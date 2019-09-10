#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

PRINT_ONLY=${PRINT_ONLY:-false}

function main() {

    setup

    reset

    runAsRoot

    allowPrivilegeEscalation

    readOnlyRootFilesystem

    echo
    message "This concludes the demo, thanks for securing your clusters!"
}

function setup() {

    source ../../config.sh

    run "gcloud -q --no-user-output-enabled container clusters get-credentials ${CLUSTER3} \
        --zone ${ZONE} \
        --project ${PROJECT}"

    run "kubectl config set-context \$(kubectl config current-context) --namespace=wild-west > /dev/null"
}

function runAsRoot() {
    heading "1. Run as root"

    subHeading "1.1 Pod runs as root"
    printAndRun "kubectl create deployment nginx --image nginx:1.17.2"
    printAndRun "kubectl exec \$(kubectl get pods  | awk '/nginx/ {print \$1;exit}') id"

    subHeading "1.2 Same with \"runAsNonRoot: true\""
    printFile 01-deployment-run-as-non-root.yaml
    printAndRun "kubectl apply -f 01-deployment-run-as-non-root.yaml"
    sleep 2
    printAndRun "kubectl get pod \$(kubectl get pods  | awk '/^run-as-non-root/ {print \$1;exit}')"
    echo
    printAndRun "kubectl describe pod \$(kubectl get pods  | awk '/^run-as-non-root/ {print \$1;exit}') | grep Error"

    subHeading "1.3 Image that runs as nginx as non-root ➜ runs as uid != 0"
    printFile 02-deployment-run-as-non-root-unprivileged.yaml
    printAndRun "kubectl exec \$(kubectl get pods  | awk '/run-as-non-root-unprivileged/ {print \$1;exit}') id"

    pressKeyToContinue
}

function allowPrivilegeEscalation() {

     heading "2. allowPrivilegeEscalation"

     subHeading "2.1 Escalate privileges"
     printAndRun "kubectl create deployment docker-sudo --image schnatterer/docker-sudo:0.1"
     sleep 1
     printAndRun "kubectl exec \$(kubectl get pods  | awk '/docker-sudo/ {print \$1;exit}') sudo apt update"

     subHeading "2.2 Same with  \"allowPrivilegeEscalation: true\" -> escalation fails"
     printFile 04-deployment-allow-no-privilege-escalation.yaml
     printAndRun "kubectl exec \$(kubectl get pods  | awk '/allow-no-privilege-escalation/ {print \$1;exit}') sudo apt update"

     pressKeyToContinue
}

function readOnlyRootFilesystem() {

     heading "3. readOnlyRootFilesystem"


     subHeading "3.1 Write to container's file system"
     printAndRun "kubectl exec \$(kubectl get pods  | awk '/docker-sudo/ {print \$1;exit}') sudo apt update"


     subHeading "3.2 Same with  \"readOnlyRootFilesystem: true\" -> fails to write to temp dirs"
     printFile 05-deployment-read-only-fs.yaml
     printAndRun "kubectl exec \$(kubectl get pods  | awk '/^read-only-fs/ {print \$1;exit}') sudo apt update"


     subHeading "( 3.2a By the way - this could also be done with a networkPolicy )"
     printFile 05a-netpol-egress-docker-sudo-allow-internal-only.yaml
     printAndRun "kubectl apply -f 05a-netpol-egress-docker-sudo-allow-internal-only.yaml"
     printAndRun "timeout 10s kubectl exec \$(kubectl get pods  | awk '/docker-sudo/ {print \$1;exit}') sudo apt update"


     subHeading "3.3 readOnlyRootFilesystem causes issues with other images"
     printFile 06-deployment-nginx-read-only-fs.yaml
     printAndRun "kubectl get pod \$(kubectl get pods  | awk '/failing-nginx-read-only-fs/ {print \$1;exit}')"
     echo
     printAndRun "kubectl logs \$(kubectl get pods  | awk '/failing-nginx-read-only-fs/ {print \$1;exit}')"

     message "How to find out which folders we need to mount?"
     printAndRun "docker run -d --rm --name nginx nginx:1.17.2"
     sleep 1
     printAndRun "docker diff nginx"
     run docker rm -f nginx > /dev/null

     message "Mount those dirs as as emptyDir!"
     printFile 07-deployment-nginx-read-only-fs-empty-dirs.yaml
     printAndRun "kubectl get pod \$(kubectl get pods  | awk '/empty-dirs-nginx-read-only-fs/ {print \$1;exit}')"
}

function heading() {
    echo
    echo -e "${RED}# ${1}${NO_COLOR}"
    echo -e "${RED}========================================${NO_COLOR}"
}

function subHeading() {
    echo
    echo -e "${GREEN}# ${1}${NO_COLOR}"
    echo
    pressKeyToContinue
}

function message() {
    echo
    echo -e "${GREEN}${1}${NO_COLOR}"
    echo
    pressKeyToContinue
}

function pressKeyToContinue() {
    if [[ "${PRINT_ONLY}" != "true" ]]; then
        read -n 1 -s -r -p "Press any key to continue"
        removeOutputLine
    fi
}

function removeOutputLine() {
    echo -en "\r\033[K"
}

function printAndRun() {
    echo "$ ${1}"
    run "${1}"
}

function run() {
    if [[ "${PRINT_ONLY}" != "true" ]]; then
        eval ${1} || true
    fi
}

function printFile() {
    bat ${1}
    pressKeyToContinue
}

function reset() {
    if [[ "${PRINT_ONLY}" != "true" ]]; then
        # Reset the changes done by this demo
        kubectlSilent delete deploy nginx
        kubectlSilent delete -f 01-deployment-run-as-non-root.yaml
        kubectlSilent delete deploy docker-sudo
        kubectlSilent delete netpol egress-nginx-allow-internal-only
    fi
}

function kubectlSilent() {
    kubectl "$@" > /dev/null 2>&1 || true
}


GREEN='\033[0;32m'
RED='\033[0;31m'
GRAY='\033[0;30m'
NO_COLOR='\033[0m'

main "$@"