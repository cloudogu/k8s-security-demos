#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

source ${ABSOLUTE_BASEDIR}/../config.sh
source ${ABSOLUTE_BASEDIR}/../utils.sh

function main() {

    createCluster "${CLUSTER1}" "1" "--enable-legacy-authorization"
    kubectl apply -f ${ABSOLUTE_BASEDIR}/web-console
    ip=$(waitForExternalIp "web-console" "default")
    writeEtcHosts "${ip}" "legacy-authz"


    createCluster "${CLUSTER2}" "2" "--enable-network-policy"
    kubectl apply -f ${ABSOLUTE_BASEDIR}/web-console
    ip=$(waitForExternalIp "web-console" "default")
    writeEtcHosts "${ip}" "rbac"
}

main "$@"