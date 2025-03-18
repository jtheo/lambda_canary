#!/usr/bin/env bash

[[ -e utils.sh ]] || (
  echo "Missing utility functions file <util.sh>"
  exit 1
)

source utils.sh

nrTests=${1:-10}
single=outfile
total=total
result=result

true >"${single}"
true >"${total}"

# shellcheck disable=SC2034
myAlias=live

if [[ ! -e lambda_url.txt ]]; then
  err "Can't find the file lambda_url.txt"
fi

url=$(cat lambda_url.txt)

start=$(date +%s)
msg "Start Testing ${nrTests} times"
while [[ ${nrTests} -gt 0 ]]; do
  # if ! aws lambda invoke --function-name mattmar1 "${single}" --qualifier "${myAlias}" >out.log 2>&1; then
  if ! curl -sSL "${url}" -o "${single}" 2>&1; then
    cat out.log
    err "Failed to invoke the lambda"
  fi
  printf "."
  (
    cat "${single}"
    echo
  ) >>"${total}"
  nrTests=$((nrTests - 1))
done

sort <"${total}" | uniq -c | sort -n >"${result}"

echo
echo
awk '{tot+=$1; vers[$5]= $1} END {for (v in vers) {p=vers[v]*100/tot; printf "%s %d requests %2.2f%%\n",v,vers[v],p} }' "${result}"
echo

rm "${single}" "${total}"
now=$(date +%s)
msg "Test took: $((now - start)) seconds"
