#!/usr/bin/env bash
PROJECT=${PROJECT:-"cloudogu-trainings"}
ZONE=${ZONE:-"us-central1-a"}

CLUSTER_VERSION=${CLUSTER_VERSION:-"1.14"}
MACHINE_TYPE=${MACHINE_TYPE:-"n1-standard-2"}

CLUSTER[1]="k8s-sec-3-things-abac"
CLUSTER_NODES[1]=1
CLUSTER_ADDITIONAL_ARGS[1]="--enable-legacy-authorization"

CLUSTER[2]="k8s-sec-3-things-rbac-nwp-psp"
CLUSTER_NODES[2]=2
CLUSTER_ADDITIONAL_ARGS[2]="--enable-pod-security-policy --enable-network-policy"

# TODO grep network poilicy hosts from ingress.yamls - grep -r "host: "
HOSTNAMES=( "legacy-authz" "rbac" "traefik" "web-console" "prometheus" "nosqlclient" )