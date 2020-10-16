#!/usr/bin/env bash
PROJECT=${PROJECT:-"cloudogu-trainings"}
ZONE=${ZONE:-"us-central1-a"}
TERRAFORM_BUCKET=${TERRAFORM_BUCKET:-"cloudogu-trainings-terraform"}

# Docs recommend to not use fuzzy version here:
# https://www.terraform.io/docs/providers/google/r/container_cluster.html
# OTOH google deprecates support for specific version rather fast.
# Resulting in "Error 400: Master version "X" is unsupported., badRequest"
# So we use a version prefix hoping that the stable patch versions won't do unexpected things (which is unlikely!) 
CLUSTER_VERSION=${CLUSTER_VERSION:-"1.16."}
MACHINE_TYPE=${MACHINE_TYPE:-"n1-standard-2"}

CLUSTER="k8s-sec-demo-rbac-nwp-psp"
CLUSTER_NODES=2

# TODO grep network poilicy hosts from ingress.yamls - grep -r "host: "
HOSTNAMES=( "legacy-authz" "rbac" "traefik" "web-console" "prometheus" "nosqlclient" )