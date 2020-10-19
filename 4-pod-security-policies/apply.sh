#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

source ${ABSOLUTE_BASEDIR}/../config.sh
source ${ABSOLUTE_BASEDIR}/../cluster-utils.sh


function main() {

    confirm "Preparing demo in kubernetes cluster '$(kubectl config current-context)'." 'Continue? y/n [n]' \
     || exit 0
     
    # Start with a privileged PSP. Makes sure deployments are allowed to create pods
    # Note that this requires the applying user to be cluster admin
    kubectl apply -f demo/psp-privileged.yaml
  
    # Start in an empty namespace for a smoother intro to the demo
    kubectlIdempotent create namespace psp
    
    kubectl config set-context $(kubectl config current-context) --namespace=psp
}

main "$@"
