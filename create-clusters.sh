#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

${ABSOLUTE_BASEDIR}/3-security-context/create-clusters.sh && \
${ABSOLUTE_BASEDIR}/2-network-policies/create-clusters.sh && \
${ABSOLUTE_BASEDIR}/1-rbac/create-clusters.sh