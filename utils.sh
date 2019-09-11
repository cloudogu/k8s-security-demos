#!/usr/bin/env bash

function waitForExternalIp() {

    local SERVICE_NAME="$1"
    local NAMESPACE="$2"

    local ip=""
    while [[ -z ${ip} ]]
    do
        ip=$(findServiceExternalIp "${SERVICE_NAME}" "${NAMESPACE}")
        sleep 1
    done

    echo "${ip}"
}

function findServiceExternalIp() {
    local NAMESPACE=${2-}

    if [[ ! -z "${NAMESPACE}" ]];
        then NAMESPACE="-n ${NAMESPACE}"
    fi

    kubectl get service $1 -o=jsonpath="{.status.loadBalancer.ingress[0].ip}" ${NAMESPACE}
}

function findIngressHostname() {
    local NAMESPACE=${2-}

    if [[ ! -z "${NAMESPACE}" ]];
        then NAMESPACE="-n ${NAMESPACE}"
    fi

    kubectl get ingress $1 -o=jsonpath="{.spec.rules[0].host}" ${NAMESPACE}
}

function writeEtcHosts() {
    local IP=$1
    local NEW_HOSTNAME=$2

    echo "Writing the following to /etc/hosts: ${IP} ${NEW_HOSTNAME}"
    echo "${IP} ${NEW_HOSTNAME}" | sudo tee --append /etc/hosts
}

function createCluster() {

    local CLUSTER="$1"
    local NUM_NODES="$2"
    local ADDITIONAL_ARGS="$3"

    if clusterExists ${CLUSTER}; then
      echo "Cluster $CLUSTER already exists. Reusing."
    else
        gcloud beta container --project ${PROJECT} clusters create ${CLUSTER} --zone ${ZONE} \
          --num-nodes "${NUM_NODES}" \
          --cluster-version ${CLUSTER_VERSION} \
          --username "admin" \
          --machine-type ${MACHINE_TYPE}  \
          --image-type "COS" \
          --disk-type "pd-standard" --disk-size "100" \
          --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
          --enable-cloud-monitoring \
          --no-enable-ip-alias \
          ${ADDITIONAL_ARGS}
    fi

    # Setup kubectl
    gcloud container clusters get-credentials ${CLUSTER} \
        --zone ${ZONE} \
        --project ${PROJECT}
}

function clusterExists() {
    gcloud beta container --project ${PROJECT} clusters list | grep "$1"
}

function becomeClusterAdmin() {
    kubectlIdempotent create clusterrolebinding myname-cluster-admin-binding \
      --clusterrole=cluster-admin \
      --user=$(gcloud info | grep Account  | sed -r 's/Account\: \[(.*)\]/\1/')
}

function kubectlIdempotent() {
    kubectl "$@" --dry-run -o yaml | kubectl apply -f -
}

function podReady() {
    local POD_NAME="$1"
    local NAMESPACE="$2"




    if [[ -z "${IS_READY}" ]]
    then
        return 1
    else
        return 0
     fi
# Checks if a pod (name is a wildcard match) is ready. Only works reliably if there is only one pod with that name.
}

function waitForPodReady() {

    local POD_NAME="$1"
    local NAMESPACE="$2"

    local isReady=""
    while [[ -z ${isReady} ]]
    do
        local isReady=$(kubectl get pod -n "${NAMESPACE}" $(kubectl get pods -n "${NAMESPACE}" | awk -v pod_name="$POD_NAME" '$0 ~ pod_name {print $1;exit}') -o json | jq '.status.conditions[] | select(.type=="Ready" and .status=="True")')
        echo "Waiting for pod ${POD_NAME} in namespace ${NAMESPACE} to become ready"
        sleep 1
    done
}
