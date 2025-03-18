#!/bin/bash

function msg() {
  # printf "%(%d-%m-%Y %H:%M:%S)T: ${*}\n"
  printf "%s: %s\n" "$(date)" "${*}"
}

function err() {
  msg "${*}"
  exit 1
}

function printEnv() {
  local list
  read -r -a list <<<"${*}"
  msg "Dump vars"
  for e in "${list[@]}"; do
    echo "- ${e}: ${!e}"
  done
  echo "${LINE}"
  echo
}

function e() {
  label=${1}
  shift
  cmd=${*}

  msg "Executing ${label}"
  set -o pipefail
  if ! ${cmd} >"${output}" 2>&1; then
    cat "${output}"
    err "Failed ${label}"
  fi
}

LINE=$(printf "%*s" 100 " " | tr ' ' '-')
