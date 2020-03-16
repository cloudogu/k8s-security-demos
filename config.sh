#!/usr/bin/env bash
PROJECT=${PROJECT:-"cloudogu-trainings"}
ZONE=${ZONE:-"us-central1-a"}

CLUSTER_VERSION=${CLUSTER_VERSION:-"1.14"}
MACHINE_TYPE=${MACHINE_TYPE:-"n1-standard-2"}

CLUSTER1="k8s-sec-3-things-abac"
CLUSTER2="k8s-sec-3-things-rbac-nwp"
CLUSTER3="k8s-sec-3-things-psp"
# TODO grep network poilicy hosts from ingress.yamls - grep -r "host: "
HOSTNAMES=( "legacy-authz" "rbac" "traefik" "web-console" "prometheus" "nosqlclient" )