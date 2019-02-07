# Security Context and Security Policy Demo

![Clusters, Namespaces and Pods](../../images/demo-sec-ctx.svg)

```bash
# Switch to proper kubectl context - alternatively use kubectx
source ../config.sh
gcloud container clusters get-credentials ${CLUSTER3} \
    --zone ${ZONE} \
    --project ${PROJECT}
    
cd demo

#### runAsNonRoot
kubectl create deployment nginx --image nginx:1.15.8
# Succeeds
kubectl exec $(kubectl get pods  | awk '/nginx/ {print $1;exit}') id

# Same with "runAsNonRoot: true"
cat 01-deployment-run-as-non-root.yaml
# Now does not even start
kubectl describe pod $(kubectl get pods  | awk '/run-as-non-root/ {print $1;exit}') | grep Error

# Image that runs as nginx as non-root
cat 02-deployment-run-as-non-root-bitnami.yaml
# Success -> uid 1001
kubectl exec $(kubectl get pods  | awk '/run-as-non-root-bitnami/ {print $1;exit}') id



#### allowPrivilegeEscalation
# Showcase with sudo - in reality this would rather be a kernel vulnerability
kubectl create deployment docker-sudo --image schnatterer/docker-sudo:0.1
# Fails
kubectl exec $(kubectl get pods  | awk '/docker-sudo/ {print $1;exit}') apt update
# Succeeds
kubectl exec $(kubectl get pods  | awk '/docker-sudo/ {print $1;exit}') sudo apt update

# Same with "allowPrivilegeEscalation: true"
cat 04-deployment-allow-no-privilege-escalation.yaml
# Now fails
kubectl exec $(kubectl get pods  | awk '/allow-no-privilege-escalation/ {print $1;exit}') sudo apt update



### readOnlyRootFilesystem
# Succeeds
kubectl exec $(kubectl get pods  | awk '/docker-sudo/ {print $1;exit}') sudo apt update

# Same with "readOnlyRootFilesystem: true"
cat 05-deployment-read-only-fs.yaml
# Now fails
kubectl exec $(kubectl get pods  | awk '/read-only-fs/ {print $1;exit}') sudo apt update

# BTW good place for a netpol
cat 05a-netpol-egress-docker-sudo-allow-internal-only.yaml
kubectl apply -f 06-netpol-egress-docker-sudo-allow-internal-only.yaml
# Now also fails
kubectl exec $(kubectl get pods  | awk '/docker-sudo/ {print $1;exit}') sudo apt update

# OTOH readOnlyRootFilesystem causes issues with other images
cat 06-deployment-nginx-read-only-fs.yaml
# container could not start, because no writable temp dir
kubectl logs $(kubectl get pods  | awk '/nginx-read-only-fs/ {print $1;exit}')
# How to find out which folders we need to mount?
#docker run -d --rm --name nginx nginx:1.15.7
#docker diff nginx | grep 'A '
# These need to be mounted as empty dirs
cat 07-deployment-nginx-read-only-fs-empty-dirs.yaml
# Now runs again
kubectl get pod $(kubectl get pods  | awk '/nginx-read-only-fs-empty-dirs/ {print $1;exit}')



### PSP
# Remove privilege psp as default
kubectl delete rolebinding default:psp:privileged
kubectl delete pod --all
kubectl get pod
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
kubectl delete pod $(kubectl get pods  | awk '/nginx/ {print $1;exit}')
# Now runs again
kubectl get pod $(kubectl get pods  | awk '/nginx/ {print $1;exit}') 

# statefulsets are also restricted by psp
cat 11-statefulset.yaml
kubectl logs stateful-0
```


