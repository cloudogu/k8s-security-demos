# RBAC Demo

![Clusters, Namespaces and Pods](http://www.plantuml.com/plantuml/svg/dL8zQyCm4DtrAmvtoEIX3OHC9RKXT0Ybj84E9SF5khWXicHE4gKj-UyzsQOr8KkYxTwzZtUWXG_88JP6-SFUjiZOmDu6uXrM13yAeC3gKBEBLfVEE8QRkobEjKuRnvfuG6zdi_bSgwCQ6I6p--nCnj8JKkMQrbcouOeqWAMpOS2MtKlcwl-2x76zVdxD03si2gMiquAL9deXWA4Qgo_063w-CubN0AtaOosS9sp8oqGmqRJ3QCAaSyc6AU_5IGRotjzeArTQxmn1lzfqz16UzSnLiO4ylpyh4ORqFvuMVIaUoeiByXQhi_MIsqNbak2lseAiJl_b5m00)

```bash
# Switch to proper kubectl context - alternatively use kubectx
source ../config.sh
gcloud container clusters get-credentials ${CLUSTER[2]} \
    --zone ${ZONE} \
    --project ${PROJECT}
    
#### Accessing the k8s API with legacy authorization
# http://legacy-authz/

# Each pods gets mounted a service account token to authenticate against k8s api server - for using cloud native features
ls /var/run/secrets/kubernetes.io/serviceaccount/
# There also a CA.crt, because als communication is done via HTTPS

# How do we find out where the API server is?➡️  Also mounted into each pod, via its env
env | grep KUBERNETES

# Let's query this URL
curl https://$KUBERNETES_SERVICE_HOST

# this is where we need to apply the CA
curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://$KUBERNETES_SERVICE_HOST

# Can we get the version?
curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt  https://$KUBERNETES_SERVICE_HOST/version
# BTW - this is publicly available via the internet. Try it out! echo https://$KUBERNETES_SERVICE_HOST/version
# So you might not want to make it attackers that easy! One reason why it is recommended to use a bastion host

# Can we also get the API? 
curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://$KUBERNETES_SERVICE_HOST/api/v1

# Lets try to get secrets➡️  Forbidden
curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://$KUBERNETES_SERVICE_HOST/api/v1/namespaces/default/secrets/web-console

# Let's use the token to authenticate➡️  exposes our secrets!
curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://$KUBERNETES_SERVICE_HOST/api/v1/namespaces/default/secrets/web-console \
  -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"


#### Accessing the k8s API with RBAC
# http://rbac➡️  Not allowed by default

curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://$KUBERNETES_SERVICE_HOST/api/v1/namespaces/default/secrets/web-console \
  -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"

# Console Window
kubectl create rolebinding web-console \
--clusterrole admin \
--serviceaccount default:web-console

# http://rbac➡️  Try the same again: Now allowed
curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt https://$KUBERNETES_SERVICE_HOST/api/v1/namespaces/default/secrets/web-console \
  -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
```


