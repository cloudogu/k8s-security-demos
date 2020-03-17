#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

PRINT_ONLY=${PRINT_ONLY:-false}

source ${ABSOLUTE_BASEDIR}/../../interactive-utils.sh

function main() {

    setup
    reset
    run "clear"

    runAsRoot

    runAsUser

    allowPrivilegeEscalation

    enableServiceLinks

    activateSeccompProfile

    dropCapabilities

    readOnlyRootFilesystem

    allAtOnce

    echo
    message "This concludes the demo, thanks for securing your clusters!"
}

function setup() {

    run "echo Setting up environment for interactive demo 'security context'"

    source ../../config.sh

    run "gcloud -q --no-user-output-enabled container clusters get-credentials ${CLUSTER[2]} \
        --zone ${ZONE} \
        --project ${PROJECT}"
    run "echo -n ."

    run "kubectl config set-context \$(kubectl config current-context) --namespace=sec-ctx > /dev/null"
    run "echo -n ."
}

function runAsRoot() {
    heading "1. Run as root"

    subHeading "1.1 Pod runs as root"
    printAndRun "kubectl create deployment nginx --image nginx:1.17.2"
    printAndRun "kubectl exec \$(kubectl get pods  | awk '/nginx/ {print \$1;exit}') id"

    subHeading "1.2 Same with \"runAsNonRoot: true\""
    printFile 01-deployment-run-as-non-root.yaml
    printAndRun "kubectl apply -f 01-deployment-run-as-non-root.yaml"
    run "sleep 3"
    printAndRun "kubectl get pod \$(kubectl get pods  | awk '/^run-as-non-root/ {print \$1;exit}')"
    pressKeyToContinue
    echo
    printAndRun "kubectl describe pod \$(kubectl get pods  | awk '/^run-as-non-root/ {print \$1;exit}') | grep Error"

    subHeading "1.3 Image that runs as nginx as non-root ➡️  runs as uid != 0"
    printFile 02-deployment-run-as-non-root-unprivileged.yaml
    printAndRun "kubectl get pod \$(kubectl get pods  | awk '/^run-as-non-root-unprivileged/ {print \$1;exit}')"
    pressKeyToContinue
    printAndRun "kubectl exec \$(kubectl get pods  | awk '/run-as-non-root-unprivileged/ {print \$1;exit}') id"

    pressKeyToContinue
}

function runAsUser() {
    heading "2. Run as user/group"

    subHeading "2.1 Runnginx as uid/gid 100000"
    printFile 03-deployment-run-as-user-unprivileged.yaml
    printAndRun "kubectl get pod \$(kubectl get pods  | awk '/run-as-user-unprivileged/ {print \$1;exit}')"
    printAndRun "kubectl exec \$(kubectl get pods  | awk '/run-as-user-unprivileged/ {print \$1;exit}') id"

    subHeading "2.2 Image must be designed to work with \"runAsUser\" and \"runAsGroup\""
    printFile 04-deployment-run-as-user.yaml
    printAndRun "kubectl apply -f 04-deployment-run-as-user.yaml"
    run "sleep 3"

    printAndRun "kubectl get pod \$(kubectl get pods  | awk '/^run-as-user/ {print \$1;exit}')"
    echo
    printAndRun "kubectl logs \$(kubectl get pods  | awk '/^run-as-user/ {print \$1;exit}')"

    pressKeyToContinue
}

function allowPrivilegeEscalation() {

     heading "3. allowPrivilegeEscalation"

     subHeading "3.1 Escalate privileges"
     printAndRun "kubectl create deployment docker-sudo --image schnatterer/docker-sudo:0.1"
     run "kubectl rollout status deployment docker-sudo > /dev/null"
     printAndRun "kubectl exec \$(kubectl get pods  | awk '/docker-sudo/ {print \$1;exit}') id"
     pressKeyToContinue

     printAndRun "kubectl exec \$(kubectl get pods  | awk '/docker-sudo/ {print \$1;exit}') sudo id"

     subHeading "3.2 Same with  \"allowPrivilegeEscalation: true\" ➡️  escalation fails"
     printFile 05-deployment-allow-no-privilege-escalation.yaml
     printAndRun "kubectl exec \$(kubectl get pods  | awk '/allow-no-privilege-escalation/ {print \$1;exit}') sudo id"

     pressKeyToContinue
}

function enableServiceLinks() {

  heading "4. enableServiceLinks"

  subHeading "4.1 Show service links"
  printAndRun "kubectl create service clusterip my-service --tcp=80:8080 || true"
  printAndRun "kubectl run tmp-env --generator=run-pod/v1 --image busybox:1.31.1-musl --command sleep 100000"
  pressKeyToContinue
  printAndRun "kubectl exec tmp-env env | sort"

  subHeading "4.2 Disable service links"
  printAndRun "kubectl run tmp-env2 --generator=run-pod/v1 --image busybox:1.31.1-musl --overrides='{\"spec\": {\"enableServiceLinks\": false}}' --command sleep 100000"
  pressKeyToContinue
  printAndRun "kubectl exec tmp-env2 env"
  pressKeyToContinue
}

function activateSeccompProfile() {

    heading "5. Enable Seccomp default profile"

    subHeading "5.1 No seccomp profile by default 😲"
    kubectlSilent create deployment nginx --image nginx:1.17.2
    printAndRun "kubectl exec \$(kubectl get pods  | awk '/nginx/ {print \$1;exit}') grep Seccomp /proc/1/status"

     subHeading "5.2 Same with  default seccomp profile"
     printFile 06-deployment-seccomp.yaml
     printAndRun "kubectl get pod \$(kubectl get pods  | awk '/run-with-seccomp/ {print \$1;exit}')"
     printAndRun "kubectl exec \$(kubectl get pods  | awk '/run-with-seccomp/ {print \$1;exit}') grep Seccomp /proc/1/status"

     pressKeyToContinue
}

function dropCapabilities() {

    heading "6. Drop Capabilities"

    subHeading "6.1 some images require capabilities"
    printFile 07-deployment-run-without-caps.yaml
    printAndRun "kubectl get pod \$(kubectl get pods  | awk '/^run-without-caps/ {print \$1;exit}')"
    echo
    printAndRun "kubectl logs \$(kubectl get pods  | awk '/^run-without-caps/ {print \$1;exit}') "

    message "How to find out which capabilities we need to add?"
    printAndRun "docker run --rm --cap-drop ALL nginx:1.17.2"
    pressKeyToContinue
    echo
    printAndRun "docker run --rm --cap-drop ALL --cap-add CAP_CHOWN nginx:1.17.2"
    pressKeyToContinue
    #printAndRun "docker run --rm --cap-drop ALL --cap-add CAP_CHOWN --cap-add CAP_NET_BIND_SERVICE nginx:1.17.2"
    #printAndRun "docker run --rm --cap-drop ALL --cap-add CAP_CHOWN --cap-add CAP_NET_BIND_SERVICE --cap-add SETGID nginx:1.17.2"
    #printAndRun "docker run --rm --cap-drop ALL --cap-add CAP_CHOWN --cap-add CAP_NET_BIND_SERVICE --cap-add SETGID --cap-add SETUID nginx:1.17.2"

    message "... and so on and so forth. Then add the necessary caps to kubernetes:"
    printFile 08-deployment-run-with-certain-caps.yaml
    printAndRun "kubectl get pod \$(kubectl get pods  | awk '/run-with-certain-caps/ {print \$1;exit}')"

    subHeading "6.2 Image that runs without caps"
    printFile 09-deployment-run-without-caps-unprivileged.yaml
    printAndRun "kubectl get pod \$(kubectl get pods  | awk '/run-without-caps-unprivileged/ {print \$1;exit}')"

    pressKeyToContinue
}

function readOnlyRootFilesystem() {

     heading "7. readOnlyRootFilesystem"
     kubectlSilent create deployment docker-sudo --image schnatterer/docker-sudo:0.1

     subHeading "7.1 Write to container's file system"
     printAndRun "kubectl exec \$(kubectl get pods  | awk '/docker-sudo/ {print \$1;exit}') sudo apt update"


     subHeading "7.2 Same with  \"readOnlyRootFilesystem: true\" ➡️  fails to write to temp dirs"
     printFile 10-deployment-read-only-fs.yaml
     printAndRun "kubectl exec \$(kubectl get pods  | awk '/^read-only-fs/ {print \$1;exit}') sudo apt update"


     subHeading "( 7.2a By the way - this could also be done with a networkPolicy )"
     read -p "Want to see? y/n [n]" answer
     while true
      do
        case ${answer} in
         [yY]* ) printFile 10a-netpol-egress-docker-sudo-allow-internal-only.yaml
                 printAndRun "kubectl apply -f 10a-netpol-egress-docker-sudo-allow-internal-only.yaml"
                 printAndRun "timeout 10s kubectl exec \$(kubectl get pods  | awk '/docker-sudo/ {print \$1;exit}') sudo apt update"
                 break;;

         * )     break ;;
        esac
      done

     subHeading "7.3 readOnlyRootFilesystem causes issues with other images"
     printFile 11-deployment-nginx-read-only-fs.yaml
     printAndRun "kubectl get pod \$(kubectl get pods  | awk '/failing-nginx-read-only-fs/ {print \$1;exit}')"
     message "Not running. Let's check the logs"
     printAndRun "kubectl logs \$(kubectl get pods  | awk '/failing-nginx-read-only-fs/ {print \$1;exit}')"

     message "How to find out which folders we need to mount?"
     printAndRun "nginxContainer=\$(docker run -d --rm nginx:1.17.2)"
     run "sleep 1"
     printAndRun "docker diff \${nginxContainer}"
     run "docker rm -f \${nginxContainer} > /dev/null"

     message "Mount those dirs as as emptyDir!"
     printFile 12-deployment-nginx-read-only-fs-empty-dirs.yaml
     printAndRun "kubectl get pod \$(kubectl get pods  | awk '/empty-dirs-nginx-read-only-fs/ {print \$1;exit}')"

     pressKeyToContinue
}

function allAtOnce() {
     heading "8. An example that implements all good practices at once"
     pressKeyToContinue

     printFile 13-deployment-all-at-once.yaml
     printAndRun "kubectl get pod \$(kubectl get pods  | awk '/all-at-once/ {print \$1;exit}')"
     pressKeyToContinue
     printAndRun "kubectl port-forward \$(kubectl get pods  | awk '/all-at-once/ {print \$1;exit}') 8080 > /dev/null& "
     run "wget -O- --retry-connrefused --tries=30 -q --wait=1 localhost:8080 > /dev/null"
     pressKeyToContinue
     printAndRun "curl localhost:8080"
     run "jobs > /dev/null && kill %1"

     pressKeyToContinue
}

function reset() {
      # Reset the changes done by this demo
      kubectlSilent delete deploy nginx
      run "echo -n ."
      kubectlSilent delete -f 01-deployment-run-as-non-root.yaml
      run "echo -n ."
      kubectlSilent delete -f 04-deployment-run-as-user.yaml
      run "echo -n ."
      kubectlSilent delete deploy docker-sudo
      run "echo -n ."
      kubectlSilent delete netpol egress-nginx-allow-internal-only
      run "echo -n ."
      kubectlSilent delete po tmp-env --grace-period=0 --force
      run "echo -n ."
      kubectlSilent delete po tmp-env2 --grace-period=0 --force
      run "echo -n ."
      kubectlSilent delete svc my-service
}

main "$@"
