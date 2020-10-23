#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

source ${ABSOLUTE_BASEDIR}/config.sh
source ${ABSOLUTE_BASEDIR}/cluster-utils.sh

function createCluster() {

  local NUM_NODES="${CLUSTER_NODES}"

  (
    cd ${ABSOLUTE_BASEDIR}/terraform && terraform init \
      -backend-config "path=.terraform/backend/${CLUSTER}" 
  )

  (
    cd ${ABSOLUTE_BASEDIR}/terraform && terraform apply \
      -var "gce_project=${PROJECT}" \
      -var "gce_location=${ZONE}" \
      -var "cluster_name=${CLUSTER}" \
      -var "credentials=account.json" \
      -var "node_count=${NUM_NODES}" \
      -var "k8s_version_prefix=${CLUSTER_VERSION}" \
      -var "machine_type=${MACHINE_TYPE}" $*
  )

  # Start with a privileged PSP. Makes sure deployments are allowed to create pods

  local ABSOLUTE_BASEDIR="$(cd $(dirname $0) && pwd)"

  # Become cluster admin, so we are authorized to create role for PSP
  becomeClusterAdmin

  kubectl apply -f ${ABSOLUTE_BASEDIR}/${PSPDIR}/psp-privileged.yaml
}

function becomeClusterAdmin() {
  kubectlIdempotent create clusterrolebinding myname-cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud info | grep Account | sed -r 's/Account\: \[(.*)\]/\1/')
  # TODO replace by kubectl whoami in order to get rid of gcloud dependency?
}

createCluster "$@"