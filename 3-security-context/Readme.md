# Security Context and Security Policy Demo

![Clusters, Namespaces and Pods](http://www.plantuml.com/plantuml/svg/dP2nQWCn38PtFuMuGZE5qWP2nj12nXB8M3gebdgOEqk7hEDIIjwzlZH3iaQJ_Vdt_u6snT5yp7qeNP813JCaSRPlZ0o_0U0LOzUQZa9lsgl1myiALqJpYngnNUZpUhtPK3Y5go8qq-bSSllr9XGr3oeiVeSDOAVY5xOxprmUH8cXEN0SBVbFjOlpqU4HzeTzKpq1OAWYR6lg7JENUcDOJAcdvSJ55mtK5DJva3R9yVF__9LSCAUdQqOQExPb6KbdKksdi6MXkj8_)

You can choose between the interactive demo:

```bash
./interactive-demo.sh
```

And the manual demo: 

```bash
# Switch to proper kubectl context - alternatively use kubectx
source ../config.sh
gcloud container clusters get-credentials ${CLUSTER3} \
    --zone ${ZONE} \
    --project ${PROJECT}

kubectl config set-context $(kubectl config current-context) --namespace=wild-west

cd demo

#### runAsNonRoot
kubectl create deployment nginx --image nginx:1.17.2
# Succeeds
kubectl exec $(kubectl get pods  | awk '/nginx/ {print $1;exit}') id

# Same with "runAsNonRoot: true"
cat 01-deployment-run-as-non-root.yaml
kubectl apply -f 01-deployment-run-as-non-root.yaml
# Now does not even start
kubectl describe pod $(kubectl get pods  | awk '/^run-as-non-root/ {print $1;exit}') | grep Error

# Image that runs as nginx as non-root
cat 02-deployment-run-as-non-root-unprivileged.yaml
# Success -> uid 1001
kubectl exec $(kubectl get pods  | awk '/run-as-non-root-unprivileged/ {print $1;exit}') id


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
kubectl exec $(kubectl get pods  | awk '/^read-only-fs/ {print $1;exit}') sudo apt update

# BTW good place for a netpol
cat 05a-netpol-egress-docker-sudo-allow-internal-only.yaml
kubectl apply -f 05a-netpol-egress-docker-sudo-allow-internal-only.yaml
# Now also fails
kubectl exec $(kubectl get pods  | awk '/docker-sudo/ {print $1;exit}') sudo apt update

# OTOH readOnlyRootFilesystem causes issues with other images
cat 06-deployment-nginx-read-only-fs.yaml
# container could not start, because no writable temp dir
kubectl logs $(kubectl get pods  | awk '/failing-nginx-read-only-fs/ {print $1;exit}')
# How to find out which folders we need to mount?
#docker run -d --rm --name nginx nginx:1.17.2
#docker diff nginx'
#docker rm -f nginx
# These need to be mounted as empty dirs
cat 07-deployment-nginx-read-only-fs-empty-dirs.yaml
# Now runs again
kubectl get pod $(kubectl get pods  | awk '/empty-dirs-nginx-read-only-fs/ {print $1;exit}')
```


