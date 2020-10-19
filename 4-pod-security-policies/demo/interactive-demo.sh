#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
BASEDIR=$(dirname $0)
ABSOLUTE_BASEDIR="$( cd ${BASEDIR} && pwd )"

PRINT_ONLY=${PRINT_ONLY:-false}

source ${ABSOLUTE_BASEDIR}/../../interactive-utils.sh
source ${ABSOLUTE_BASEDIR}/../../cluster-utils.sh

function main() {

    confirm "Preparing demo in kubernetes cluster '$(kubectl config current-context)'." 'Continue? y/n [n]' \
     || exit 0
     
    setup
    reset
    run "clear"
    privilegedPsp
    
    RemoveDefaultPsp
    
    introduceRestrictedPsp
    
    adhereToRestrictivePsp
    
    useLessRestrictivePsp
    
    echo
    message "This concludes the demo, thanks for securing your clusters!"
}

function setup() {

    run "echo Setting up environment for interactive demo 'pod security policy'"

    source ${ABSOLUTE_BASEDIR}/../../config.sh

    run "echo -n ."

    run "kubectl config set-context \$(kubectl config current-context) --namespace=psp > /dev/null"
    run "echo -n ."
}

function privilegedPsp() {
  heading "With privileged PSP"
    
  subHeading "Start a pod (via a deployment)"
  printAndRun "kubectl create deployment nginx --image nginx:1.19.3"
  
  echo
  local podName="$(kubectl get pod  | awk '/^nginx/ {print $1;exit}')"
  waitForPodReady "${podName}" psp
  printAndRun "kubectl get pod \$(kubectl get pod  | awk '/^nginx/ {print \$1;exit}')"
  
  subHeading "It uses a privileged predefined PSP"
  printAndRun "kubectl get pod \$(kubectl get pod  | awk '/^nginx/ {print \$1;exit}') -o jsonpath='{.metadata.annotations.kubernetes\.io/psp}'  "
  echo
  pressKeyToContinue
  printFile ${ABSOLUTE_BASEDIR}/psp-privileged.yaml
  
  pressKeyToContinue
}
    
function RemoveDefaultPsp() {
  heading "Remove privileged default PSP"
  
  # Remove privilege PSP as default
  subHeading "Delete privileged PSP"
  printAndRun "kubectl delete clusterrolebinding podsecuritypolicy:all-serviceaccounts"
  
  subHeading "'Restart' all pods"
  printAndRun "kubectl delete pod --all"
  
  subHeading "Are there any pods?"
  printAndRun "kubectl get pod"
  
  subHeading "Why are there no pods? Lets check controllers. Here: Deployment ➡️  ReplicaSets"
  printAndRun "kubectl get rs"
  pressKeyToContinue
  printAndRun "kubectl describe rs \$(kubectl get rs  | awk '/nginx/ {print \$1;exit}') | grep Error"
  
  pressKeyToContinue
}

function introduceRestrictedPsp() {
  heading "Introduce restricted PSP"

  subHeading "Apply PSP"
  printFile ${ABSOLUTE_BASEDIR}/01-psp-restrictive.yaml
  (cd ${ABSOLUTE_BASEDIR} && printAndRun "kubectl apply -f 01-psp-restrictive.yaml") 
  
  # Delete replica sets -> Deployments create new ones which adhere to new PSP
  subHeading "'Restart' all pods"
  printAndRun "kubectl delete rs --all"
  
  subHeading "Lets check ReplicaSets"
  printAndRun "kubectl get rs"
  pressKeyToContinue
  subHeading "Lets check Pod"
  printAndRun "kubectl get pod \$(kubectl get pod  | awk '/^nginx/ {print \$1;exit}')"
  pressKeyToContinue
  printAndRun "kubectl logs \$(kubectl get pod | awk '/nginx/ {print \$1;exit}') | grep emerg"
  
  pressKeyToContinue
}

function adhereToRestrictivePsp() {
  heading "Adhere to restricted PSP"
  
  subHeading "Best Option: Adapt application to adhere to PSP"
  printFile ${ABSOLUTE_BASEDIR}/01b-nginx-unprivileged.yaml
  (cd ${ABSOLUTE_BASEDIR} && printAndRun "kubectl apply -f 01b-nginx-unprivileged.yaml") 
  
  echo
  local podName="$(kubectl get pod  | awk '/unprivileged/ {print $1;exit}')"
  waitForPodReady "${podName}" psp
  printAndRun "kubectl get pod \$(kubectl get pod  | awk '/unprivileged/ {print \$1;exit}')"
  
  pressKeyToContinue
}
    
function useLessRestrictivePsp() {
  heading "Alternative (less secure): Use less restrictive PSP for certain pod"
  
  subHeading "'Whitelist' pod to use less restrictive PSP"
  printFile ${ABSOLUTE_BASEDIR}/02a-psp-whitelist.yaml
  (cd ${ABSOLUTE_BASEDIR} && printAndRun "kubectl apply -f 02a-psp-whitelist.yaml")
  
  subHeading "Use service account for nginx pod"
  printFile ${ABSOLUTE_BASEDIR}/02b-patch-nginx-service-account.yaml
  (cd ${ABSOLUTE_BASEDIR} && printAndRun "kubectl patch deployment nginx --patch \"\$(cat 02b-patch-nginx-service-account.yaml)\"")
  
  printAndRun "kubectl delete pod \$(kubectl get pods  | awk '/^nginx/ {print \$1;exit}')"
  
  subHeading "It's running!"
  printAndRun "kubectl get pod \$(kubectl get pods  | awk '/^nginx/ {print \$1;exit}')"

  pressKeyToContinue 
}

function reset() {
  # Reset the changes done by this demo
  kubectlSilent delete deploy nginx
  run "echo -n ."
  kubectlSilent delete deploy nginx-unprivileged
  run "echo -n ."
  kubectlSilent delete -f ${ABSOLUTE_BASEDIR}/01-psp-restrictive.yaml
  run "echo -n ."
  kubectlSilent delete -f ${ABSOLUTE_BASEDIR}/02a-psp-whitelist.yaml
  run "echo -n ."
  kubectlSilent apply -f ${ABSOLUTE_BASEDIR}/psp-privileged.yaml
  run "echo -n ."
}

main "$@"