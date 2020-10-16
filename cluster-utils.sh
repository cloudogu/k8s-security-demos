#!/usr/bin/env bash

PSPDIR=../4-pod-security-policies/demo

function waitForExternalIp() {

  local SERVICE_NAME="$1"
  local NAMESPACE="$2"

  local ip=""
  while [[ -z ${ip} ]]; do
    ip=$(findServiceExternalIp "${SERVICE_NAME}" "${NAMESPACE}")
    sleep 1
  done

  echo "${ip}"
}

function findServiceExternalIp() {
  local NAMESPACE=${2-}

  if [[ ! -z "${NAMESPACE}" ]]; then
    NAMESPACE="-n ${NAMESPACE}"
  fi

  kubectl get service $1 -o=jsonpath="{.status.loadBalancer.ingress[0].ip}" ${NAMESPACE}
}

function findIngressHostname() {
  local NAMESPACE=${2-}

  if [[ ! -z "${NAMESPACE}" ]]; then
    NAMESPACE="-n ${NAMESPACE}"
  fi

  kubectl get ingress $1 -o=jsonpath="{.spec.rules[0].host}" ${NAMESPACE}
}

function writeEtcHosts() {
  local IP=$1
  local NEW_HOSTNAME=$2

  echo "Writing the following to /etc/hosts: ${IP} ${NEW_HOSTNAME}"
  echo "${IP} ${NEW_HOSTNAME}" | sudo tee --append /etc/hosts
}

function kubectlIdempotent() {
  kubectl "$@" --dry-run=client -o yaml | kubectl apply -f -
}

function waitForPodReady() {

  local POD_NAME="$1"
  local NAMESPACE="$2"

  local isReady=""
  while [[ -z ${isReady} ]]; do
    local isReady=$(kubectl get pod -n "${NAMESPACE}" $(kubectl get pods -n "${NAMESPACE}" | awk -v pod_name="$POD_NAME" '$0 ~ pod_name {print $1;exit}') -o json | jq '.status.conditions[] | select(.type=="Ready" and .status=="True")')
    echo "Waiting for pod ${POD_NAME} in namespace ${NAMESPACE} to become ready"
    sleep 1
  done
  # For some reasons pods still refuse after they are ready :-/
  sleep 1
}
