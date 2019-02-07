#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

source ${ABSOLUTE_BASEDIR}/../config.sh
source ${ABSOLUTE_BASEDIR}/../utils.sh


function main() {

    createCluster "${CLUSTER2}" "2" "--enable-network-policy"

    # Become cluster admin, so we are authorized to make traefik cluster admin
    becomeClusterAdmin

    kubectl apply -f ${ABSOLUTE_BASEDIR}/namespaces
    # Assign label to kube-system namespace so we can match it in network policies
    kubectl label namespace/kube-system namespace=kube-system

    helm init
    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
    waitForPodReady tiller kube-system

    kubectl apply -f ${ABSOLUTE_BASEDIR}/traefik/traefik-basic-console-basic-auth-secret.yaml
    helm install --name traefik --namespace kube-system --version 1.59.2 \
        --values ${ABSOLUTE_BASEDIR}/traefik/values.yaml \
        stable/traefik

    externalIp=$(waitForExternalIp "traefik" "kube-system")
    writeEtcHosts "${externalIp}" "$(findIngressHostname "traefik-dashboard" "kube-system")"

    kubectl apply -f ${ABSOLUTE_BASEDIR}/../1-rbac/web-console
    kubectl apply -f ${ABSOLUTE_BASEDIR}/web-console
    writeEtcHosts "${externalIp}" "$(findIngressHostname "web-console" "default")"

    kubectl apply -f ${ABSOLUTE_BASEDIR}/prometheus/prometheus-basic-auth-secret.yaml
    helm install --name prometheus --namespace=monitoring --version 7.1.0 \
        --values ${ABSOLUTE_BASEDIR}/prometheus/values.yaml \
        stable/prometheus

    writeEtcHosts "${externalIp}" "$(findIngressHostname "prometheus-server" "monitoring")"

    # Make sure mongodb is applied first, otherwise adminmongo seems not to show predefined DB
    kubectl apply -f ${ABSOLUTE_BASEDIR}/mongodb/mongodb-service.yaml
    kubectl apply -f ${ABSOLUTE_BASEDIR}/mongodb/mongodb-statefulset.yaml
    waitForPodReady mongodb production

    kubectl -n production cp ${ABSOLUTE_BASEDIR}/users.json mongodb-0:/tmp/users.json
    # Data taken from https://swapi.co/api/people/?format=json
    kubectl -n production exec mongodb-0 -- mongoimport -d users -c users --jsonArray /tmp/users.json

    kubectl apply -f ${ABSOLUTE_BASEDIR}/mongodb
    writeEtcHosts "${externalIp}" "$(findIngressHostname "nosqlclient" "production")"
}

main "$@"