#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

source ${ABSOLUTE_BASEDIR}/../config.sh
source ${ABSOLUTE_BASEDIR}/../cluster-utils.sh

source ${ABSOLUTE_BASEDIR}/../interactive-utils.sh

function main() {

    confirm "Preparing demo in kubernetes cluster '$(kubectl config current-context)'." 'Continue? y/n [n]' \
     || exit 0
    
    kubectl apply -f ${ABSOLUTE_BASEDIR}/namespaces
    # Assign label to kube-system namespace so we can match it in network policies
    kubectlIdempotent label namespace/kube-system namespace=kube-system --overwrite

    # Note that this requires the applying user to be cluster admin
    kubectl apply -f ${ABSOLUTE_BASEDIR}/traefik/traefik-basic-console-basic-auth-secret.yaml
    
    helm repo add center https://repo.chartcenter.io
    
    helm upgrade --install traefik --namespace kube-system --version 1.59.2 \
        --values ${ABSOLUTE_BASEDIR}/traefik/values.yaml \
        center/stable/traefik

    externalIp=$(waitForExternalIp "traefik" "kube-system")
    writeEtcHosts "${externalIp}" "$(findIngressHostname "traefik-dashboard" "kube-system")"

    kubectl apply -f ${ABSOLUTE_BASEDIR}/web-console
    writeEtcHosts "${externalIp}" "$(findIngressHostname "web-console" "default")"

    kubectl apply -f ${ABSOLUTE_BASEDIR}/prometheus/prometheus-basic-auth-secret.yaml
    
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm upgrade --install prometheus --namespace=monitoring --version 11.16.2 \
        --values ${ABSOLUTE_BASEDIR}/prometheus/values.yaml \
         prometheus-community/prometheus

    writeEtcHosts "${externalIp}" "$(findIngressHostname "prometheus-server" "monitoring")"

    # Make sure mongodb is applied first, otherwise adminmongo seems not to show predefined DB
    helm upgrade --install mongo --namespace=production --version 9.2.4 \
        --values ${ABSOLUTE_BASEDIR}/mongodb/values.yaml \
         bitnami/mongodb
    waitForPodReady mongodb production

    kubectl -n production cp ${ABSOLUTE_BASEDIR}/users.json mongodb-0:/tmp/users.json
    # Data taken from https://swapi.co/api/people/?format=json
    kubectl -n production exec mongodb-0 -- mongoimport -d users -c users --jsonArray /tmp/users.json

    find ${ABSOLUTE_BASEDIR}/mongodb -name 'nosqlclient*' -exec kubectl apply -f {} \;
    writeEtcHosts "${externalIp}" "$(findIngressHostname "nosqlclient" "production")"
}

main "$@"