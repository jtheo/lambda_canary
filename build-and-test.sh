#!/usr/bin/env bash

[[ -e ${0%/*}/utils.sh ]] || (
  echo "Missing utility functions file <util.sh>"
  exit 1
)
source utils.sh

function setWeight() {
  # ver=$((versionForAlias + 1))
  percent=${1}
  cat <<EOF | jq -rc
{
  "AdditionalVersionWeights" : {
    "${versionForAlias}" : ${percent}
  } 
}
EOF
}

function mul() {
  echo "${1} ${2}" | awk '{print $1 * $2}'
}

function getAliasInfo() {
  if ! aws lambda get-alias --function-name mattmar1 --name live >"${output}" 2>&1; then
    cat "${output}"
    err "Failed getting alias info"
  fi
  cat "${output}"
}

function getRoutingOption() {
  getAliasInfo | jq -rc .RoutingConfig.AdditionalVersionWeights
}

function rollback() {
  if ! aws lambda update-alias --function-name mattmar1 --name live --function-version "${liveFunctionVersion}" --routing-config '{}' >"${output}" 2>&1; then
    cat "${output}"
    err "Failed to update lambda mattmar1 version ${versionForAlias} to 100%"
  fi
  msg "Rollback completed"
}

start=$(date +%s)

[[ -d dist ]] || mkdir -p dist

output=/tmp/lambda-canary.log
DEST=bootstrap
export CGO_ENABLED=0 GOARCH=amd64 GOOS=linux

liveFunctionVersion=$(getAliasInfo | jq -r .FunctionVersion)
version=$((liveFunctionVersion + 1))

printEnv liveFunctionVersion

msg "Building lambda"
if ! go build -tags lambda.norpc -ldflags "-s -w -X 'main.Version=v${version}'" -o "${DEST}" main.go >"${output}" 2>&1; then
  cat "${output}"
  err "Build failed"
fi

msg "Preparing zip"
if ! zip -q -FS bootstrap.zip "${DEST}" >"${output}" 2>&1; then
  cat "${output}"
  err "Zip Failed"
fi

msg "Updating lambda"
if ! aws lambda update-function-code --function-name mattmar1 --zip-file fileb://bootstrap.zip >"${output}" 2>&1; then
  cat "${output}"
  err "Error updating lambda"
fi

msg "Waiting for the lambda to be updated"
if ! aws lambda wait function-updated --function-name mattmar1 >"${output}" 2>&1; then
  cat "${output}"
  err "Error while waiting for update"
fi

msg "Publish lambda"
if ! aws lambda publish-version --function-name mattmar1 >"${output}" 2>&1; then
  cat "${output}"
  err "Error publishing lambda"
fi

msg "Get version"
if ! aws lambda list-versions-by-function --function-name mattmar1 >"${output}" 2>&1; then
  cat "${output}"
  err "Failed to list versions"
fi

versionForAlias=$(jq -rc '[.Versions[].Version | select(match("\\d+"))] | reverse | .[0]' "${output}")

for i in {1..4}; do
  percent=$(mul "${i}" 0.25)
  absperc=$(mul "${percent}" 100)
  remperc=$((100 - absperc))
  msg "${absperc}% Traffic new version ${versionForAlias}, ${remperc}% remainging to old version ${liveFunctionVersion}"
  # shellcheck disable=SC2086
  if ! aws lambda update-alias --function-name mattmar1 --name "live" --routing-config "$(setWeight ${percent})" >"${output}" 2>&1; then
    cat "${output}"
    err "Error creating alias"
  fi
  if [[ ${absperc} -eq 100 ]]; then
    if ! aws lambda update-alias --function-name mattmar1 --name live --function-version "${versionForAlias}" --routing-config '{}' >"${output}" 2>&1; then
      cat "${output}"
      err "Failed to update lambda mattmar1 version ${versionForAlias} to 100%"
    fi
  fi

  msg "Testing with Routing Option $(getRoutingOption)"
  ./test.sh 10

  [[ ${absperc} -eq 100 ]] && break

  read -r -n 1 -t 5 -p "Rollback [y/n]? " ans
  case ${ans} in
    [yY])
      msg "Ans is <${ans}>"
      echo
      rollback
      break
      ;;
  esac
  echo
done
printf "%s" "${version}" >version

rm bootstrap bootstrap.zip

now=$(date +%s)
msg "${0} executed in $((now - start)) seconds"
