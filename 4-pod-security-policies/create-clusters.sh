#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

source ${ABSOLUTE_BASEDIR}/../config.sh
source ${ABSOLUTE_BASEDIR}/../cluster-utils.sh


function main() {

    createCluster 2

    # Start in an empty namespace for a smoother intro to the demo
    kubectlIdempotent create namespace psp
    
    kubectl config set-context $(kubectl config current-context) --namespace=psp
    
    kubectl apply -f ${ABSOLUTE_BASEDIR}/demo/03-statefulset.yaml
}

main "$@"
