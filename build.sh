#!/bin/bash

function log() {
  echo "$(date): ${*}"
}

function err() {
  log "${*}"
  exit 1
}
function printEnv() {
  local list
  read -r -a list <<<"${*}"
  log "Dump vars"
  for e in "${list[@]}"; do
    echo "- ${e}: ${!e}"
  done
  echo "${LINE}"
  echo
}

[[ -d dist ]] || mkdir -p dist

ERROR=0
DEST=bootstrap
export CGO_ENABLED=0 GOARCH=amd64 GOOS=linux

version=$(cat version)

version=$((version + 1))

printEnv CGO_ENABLED GOARCH GOOS DEST

log "Building lambda"
if ! go build -tags lambda.norpc -ldflags "-s -w -X 'main.Version=v${version}'" -o "./dist/${DEST}" main.go; then
  err "Failed to build"
fi

log "Preparing zip"
cd dist || err "Can't cd to dist"
if ! zip -q -FS bootstrap.zip "${DEST}" >out.log 2>&1; then
  err "Failed to zip"
fi

log "Updating lambda"
if ! aws lambda update-function-code --function-name mattmar1 --zip-file fileb://bootstrap.zip >out.log 2>&1; then
  cat out.log
  err "Error updating lambda"
fi

log "Waiting for the lambda to be updated"
if ! aws lambda wait function-updated --function-name mattmar1 >out.log 2>&1; then
  cat out.log
  err "Error while waiting for update"
fi

log "Publish lambda"
if ! aws lambda publish-version --function-name mattmar1 >out.log 2>&1; then
  cat out.log
  err "Error publishing lambda"
fi

log "Get version"
if ! aws lambda list-versions-by-function --function-name mattmar1 >out.log 2>&1; then
  cat out.log
  err "Failed to list versions"
fi

versionForAlias=$(jq -rc '[.Versions[].Version | select(match("\\d+"))] | sort |reverse | .[0]' out.log)

log "Create Alias"
if ! aws lambda create-alias --function-name mattmar1 --name canary --function-version "${versionForAlias}" >out.log 2>&1; then
  cat out.log
  err "Failed creating alias"
fi

log "5% Traffic to new version"
if ! aws lambda update-alias --function-name mattmar1 --name canary --routing-config '{"AdditionalVersionWeights" : {"2" : 0.05} }' >out.log 2>&1; then
  cat out.log
  err "Error creating alias"
fi

printf "%s" "${version}" >version
