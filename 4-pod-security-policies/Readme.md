# Security Policy Demo

![Clusters, Namespaces and Pods](http://www.plantuml.com/plantuml/svg/dP2nQWCn38PtFuMuGZE5qWP2nj12nXB8M3gebdgOEqk7hEDIIjwzlZH3iaQJ_Vdt_u6snT5yp7qeNP813JCaSRPlZ0o_0U0LOzUQZa9lsgl1myiALqJpYngnNUZpUhtPK3Y5go8qq-bSSllr9XGr3oeiVeSDOAVY5xOxprmUH8cXEN0SBVbFjOlpqU4HzeTzKpq1OAWYR6lg7JENUcDOJAcdvSJ55mtK5DJva3R9yVF__9LSCAUdQqOQExPb6KbdKksdi6MXkj8_)

```bash
# Switch to proper kubectl context - alternatively use kubectx
source ../config.sh
gcloud container clusters get-credentials ${CLUSTER3} \
    --zone ${ZONE} \
    --project ${PROJECT}

kubectl config set-context $(kubectl config current-context) --namespace=wild-west

cd demo

# Remove privilege psp as default
kubectl delete rolebinding default:psp:privileged
kubectl delete pod --all
kubectl get pod
# No pods started -> See replica sets for errors
kubectl describe rs $(kubectl get rs  | awk '/nginx-read-only-fs-empty-dirs/ {print $1;exit}') | grep Error
# Error creating: pods "nginx-read-only-fs-empty-dirs-f7676b7d8-" is forbidden: unable to validate against any pod security policy: []
# replicasets are no longer allowed to schedule pods

# Use the PSP that is more restrictive
cat 09-psp-more-restrictive.yaml
kubectl apply -f 09-psp-more-restrictive.yaml
# Delete replica sets -> Deployments create new ones which adhere to new PSP
kubectl delete rs --all
watch kubectl get pods
# Most pods are failing - why?
kubectl get pod $(kubectl get pods  | awk '/nginx/ {print $1;exit}') -o yaml --export | grep -A4 securityContext
# The new ReplicaSets set the securityContext adhering to PSP -> e.g. original nginx image cannot run as uid 1

### One option: "Whitelist" pod to use privileged psp
cat 10a-psp-whitelist.yaml
kubectl apply -f 10a-psp-whitelist.yaml
# Use service account for nginx pod 
cat 10b-patch-nginx-service-account.yaml
kubectl patch deployment nginx --patch "$(cat 10b-patch-nginx-service-account.yaml)"
kubectl delete pod $(kubectl get pods  | awk '/^nginx/ {print $1;exit}')
# Now runs again
kubectl get pod $(kubectl get pods  | awk '/^nginx/ {print $1;exit}') 

# statefulsets are also restricted by psp
cat 11-statefulset.yaml
kubectl describe statefulset stateful | grep error
```


