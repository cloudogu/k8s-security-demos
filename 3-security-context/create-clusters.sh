#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"
PSPDIR=${ABSOLUTE_BASEDIR}/../4-pod-security-policies/demo

source ${ABSOLUTE_BASEDIR}/../config.sh
source ${ABSOLUTE_BASEDIR}/../utils.sh


function main() {

    createCluster "${CLUSTER3}" "2" "--enable-pod-security-policy --enable-network-policy "

    # Become cluster admin, so we are authorized to create role for PSP
    becomeClusterAdmin

    # Make sure we're in a namespace that does not have any netpols
    kubectlIdempotent create namespace wild-west
    kubectl config set-context $(kubectl config current-context) --namespace=wild-west

    # Start with a privileged PSP. Makes sure deployments are allowed to create pods
    kubectl apply -f ${PSPDIR}/psp-privileged.yaml
    kubectlIdempotent create role psp:privileged \
        --verb=use \
        --resource=podsecuritypolicy \
        --resource-name=privileged
    kubectlIdempotent create rolebinding default:psp:privileged \
        --role=psp:privileged \
        --serviceaccount=wild-west:default

    kubectl apply -f ${ABSOLUTE_BASEDIR}/demo/02-deployment-run-as-non-root-unprivileged.yaml
    kubectl apply -f ${ABSOLUTE_BASEDIR}/demo/03-deployment-run-as-user-unprivileged.yaml
    kubectl apply -f ${ABSOLUTE_BASEDIR}/demo/05-deployment-allow-no-privilege-escalation.yaml
    kubectl apply -f ${ABSOLUTE_BASEDIR}/demo/06-deployment-seccomp.yaml
    kubectl apply -f ${ABSOLUTE_BASEDIR}/demo/07-deployment-run-without-caps.yaml
    kubectl apply -f ${ABSOLUTE_BASEDIR}/demo/08-deployment-run-with-certain-caps.yaml
    kubectl apply -f ${ABSOLUTE_BASEDIR}/demo/09-deployment-run-without-caps-unprivileged.yaml
    kubectl apply -f ${ABSOLUTE_BASEDIR}/demo/10-deployment-read-only-fs.yaml
    kubectl apply -f ${ABSOLUTE_BASEDIR}/demo/11-deployment-nginx-read-only-fs.yaml
    kubectl apply -f ${ABSOLUTE_BASEDIR}/demo/12-deployment-nginx-read-only-fs-empty-dirs.yaml
    kubectl apply -f ${ABSOLUTE_BASEDIR}/demo/13-deployment-all-at-once.yaml
}

main "$@"
