#!/usr/bin/env bash

GREEN='\033[0;32m'
RED='\033[0;31m'
GRAY='\033[0;30m'
NO_COLOR='\033[0m'

CAT=$(if [[ -x "$(command -v bat)" ]]; then echo "bat"; else echo "cat"; fi)

function heading() {
    echo
    echo -e "${RED}# ${1}${NO_COLOR}"
    echo -e "${RED}========================================${NO_COLOR}"
}

function subHeading() {
    echo
    echo -e "${GREEN}# ${1}${NO_COLOR}"
    echo
    pressKeyToContinue
}

function message() {
    echo
    echo -e "${GREEN}${1}${NO_COLOR}"
    echo
    pressKeyToContinue
}

function pressKeyToContinue() {
    if [[ "${PRINT_ONLY}" != "true" ]]; then
        read -n 1 -s -r -p "Press any key to continue"
        removeOutputLine
    fi
}

function confirm() {
  # shellcheck disable=SC2145
  # - the line break between args is intended here!
  printf "%s\n" "${@:-Are you sure? [y/N]} "
  
  read -r response
  case "$response" in
  [yY][eE][sS] | [yY])
    true
    ;;
  *)
    false
    ;;
  esac
}

function removeOutputLine() {
    echo -en "\r\033[K"
}

function printAndRun() {
    echo "$ ${1}"
    run "${1}"
}

function run() {
    if [[ "${PRINT_ONLY}" != "true" ]]; then
        eval ${1} || true
    fi
}

function printFile() {
    ${CAT} ${1}
    pressKeyToContinue
}

function kubectlSilent() {
    if [[ "${PRINT_ONLY}" != "true" ]]; then
      kubectl "$@" > /dev/null 2>&1 || true
    fi
}