#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

source ${ABSOLUTE_BASEDIR}/config.sh
source ${ABSOLUTE_BASEDIR}/utils.sh

function main() {
    deleteHostNames

    deleteClusterIfExists ${CLUSTER1} ${CLUSTER2} ${CLUSTER3}
}

function deleteClusterIfExists() {
    local clusters=""

    for cluster in "$@"; do
        if clusterExists ${cluster}; then
            clusters="$clusters $cluster"
        fi
    done

    # TODO For some reason this script returns -1, even when clusters are deleted
    set +x
    if [[ ! -z "${clusters}" ]]
    then
        yes | gcloud beta container --project ${PROJECT} clusters delete ${clusters} --zone ${ZONE}
    else
        echo No cluster exists. Skipping deletion
     fi
}

function deleteHostNames() {

    echo "Deleting entries from /etc/hosts: ${HOSTNAMES[@]}"

    for NAME in "${HOSTNAMES[@]}"
    do
       sudo sed -i "/${NAME}/d" /etc/hosts
    done
}

main "$@"