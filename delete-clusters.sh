#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

source ${ABSOLUTE_BASEDIR}/config.sh
source ${ABSOLUTE_BASEDIR}/cluster-utils.sh

function main() {
    deleteHostNames

    deleteClusterIfExists
}

function deleteClusterIfExists() {
  (
    cd terraform && terraform init \
      -backend-config "path=${CLUSTER}" \
      -backend-config "bucket=${TERRAFORM_BUCKET}" \
      -backend-config "credentials=account.json" \
  )

  (
    cd terraform && terraform destroy \
        -var "gce_project=${PROJECT}" \
        -var "gce_location=${ZONE}" \
        -var "cluster_name=${CLUSTER}" \
        -var "credentials=account.json" \
        -var "node_count=0" \
        -var "k8s_version_prefix=dontcare" \
        -var "machine_type=dontcare"
  )
    
  # TODO delete context as well?
  #kubectl config view --template='{{ range .contexts }}{{ if eq .name "'$(kubectl config current-context)'" }}{{ .context.cluster }}{{ end }}{{ end }}'
}

function deleteHostNames() {

    echo "Deleting entries from /etc/hosts: ${HOSTNAMES[@]}"

    for NAME in "${HOSTNAMES[@]}"
    do
       sudo sed -i "/${NAME}/d" /etc/hosts
    done
}

main "$@"