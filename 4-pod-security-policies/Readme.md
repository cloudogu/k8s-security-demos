# Pod Security Policy Demo

Note: This demo uses the same cluster as [Security Context](../3-security-context/Readme.md). 

```bash
# Switch to proper kubectl context - alternatively use kubectx
source ../config.sh
gcloud container clusters get-credentials ${CLUSTER3} \
    --zone ${ZONE} \
    --project ${PROJECT}
kubectl config set-context $(kubectl config current-context) --namespace=wild-west

cd demo

kubectl apply -f 03-statefulset.yaml

# Make simple deployment
kubectl create deployment nginx --image nginx:1.17.2 --dry-run -o yaml | kubectl apply -f -
# It's running!
kubectl get pod $(kubectl get pod  | awk '/^nginx/ {print $1;exit}')

# Remove privilege PSP as default
kubectl delete rolebinding default:psp:privileged
kubectl delete pod --all
kubectl get pod
# No pods started -> See replica sets for errors
kubectl describe rs $(kubectl get rs  | awk '/all-at-once/ {print $1;exit}') | grep Error
# Error creating: pods "nginx-read-only-fs-empty-dirs-f7676b7d8-" is forbidden: unable to validate against any pod security policy: []
# replicasets are no longer allowed to schedule pods

# Use PSP that is more restrictive
cat 01-psp-restrictive.yaml
kubectl apply -f 01-psp-restrictive.yaml
# Delete replica sets -> Deployments create new ones which adhere to new PSP
kubectl delete rs --all
watch kubectl get pods
# Pods that comply with PSP are now running, e.g.
kubectl get pod $(kubectl get pods  | awk '/all-at-once/ {print $1;exit}')
# But Most pods are failing - why?
# The new ReplicaSets set the securityContext adhering to PSP -> e.g. original nginx image cannot run as uid 1
kubectl describe pod $(kubectl get pods  | awk '/^nginx/ {print $1;exit}')  | grep Error

### Best Option: Change deployment to adhere to PSP
cat ../../3-security-context/demo/13-deployment-all-at-once.yaml | grep -A8 securityContext

### Less secure alternative: "Whitelist" pod to use less restrictive PSP
cat 02a-psp-whitelist.yaml
kubectl apply -f 02a-psp-whitelist.yaml
# Use service account for nginx pod 
cat 02b-patch-nginx-service-account.yaml
kubectl patch deployment nginx --patch "$(cat 02b-patch-nginx-service-account.yaml)"
kubectl delete pod $(kubectl get pods  | awk '/^nginx/ {print $1;exit}')
# Now runs again
kubectl get pod $(kubectl get pods  | awk '/^nginx/ {print $1;exit}') 

# statefulsets are also restricted by PSP
cat 03-statefulset.yaml
kubectl describe pod stateful-0 | grep error
```


