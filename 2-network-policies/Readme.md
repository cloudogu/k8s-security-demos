# NetworkPolicy Demo

![Clusters, Namespaces, Pods and allowed routes](https://www.plantuml.com/plantuml/svg/dL1BQzj04BxhLspLGawoP9icGfGG70Y5Xf23eOVMXzNks5wqcjdk0rEA_tjtPRKMwGCJNRGptsE-cJldkVMXrzaRXK872S5gjlVUkAOiBJ_CTihlGniSM47e0VrCK5_sIkmLwD9eZabUTA45Y-315SvO5Vzbpvq7Mrfm5Ao0igj_OqL0pLlG88l5UoFyJAK8cUiK6cvvpnH6wPOBO3yonbPST3jB0UKzQRBixMB9br8cXAm4EtRdrzTrBRFZr8XRIuV1P2fzGOeR6K90_uffZ3qG-h7tC7p9F3jla7zShvzpnXrxN6KPaeojJxLZzpga0-LnQ7GnSIhVHUY9z-1C4bwbenRkUsJrLud6ulTbRJbiLRT9XlbOv2VeSRLXHN5xvcHiibl-uHs2DwHll-8J-6VIRaY5PXvvnt-5aB3bGVjpWC_GncEY8msR5v66uLESDUm0RI5EPLDN5oPQ_2-HiII3y8emXRhGSNcAYkI-QQ5L9Fyr_1IFuITbiwogwW-JKTOJxaYsIJ8-c_BNOt5JpM-6VOxP7Q0ClVu9)

## Demo Overview

* Query users from mongo, traefik dashboard, prometheus
* Enable Block all NW Policies in production namespace
* No longer query users
* But: Ingress not working, mongo not reachable
* Whitelist
* Advanced ingress and egress topics
* See the [network-policies](network-policies) folder for YAML representation of the applied Network Policies.

## Demo Listing

`apply.sh` deploys the applications required for the demos.

Then you can start the demo:

```shell script
# Switch to proper kubectl context - alternatively use kubectx
source ../config.sh
gcloud container clusters get-credentials ${CLUSTER[2]} \
    --zone ${ZONE} \
    --project ${PROJECT}
## Reset
kubectl delete netpol --all -n production
kubectl delete netpol --all -n default
kubectl delete netpol --all -n kube-system
kubectl delete netpol --all -n monitoring


#### All traffic is allowed
# http://web-console
curl https://fastdl.mongodb.org/linux/mongodb-shell-linux-x86_64-debian92-4.4.1.tgz | tar zxv -C /tmp
mv /tmp/mongo*/bin/mongo /tmp/
/tmp/mongo users --host mongodb.production.svc.cluster.local --eval 'db.users.find().pretty()'
curl traefik-prometheus.kube-system.svc.cluster.local:9100/metrics
curl prometheus-server.monitoring.svc.cluster.local/graph

#### Deny all Network Policy
# Console Window
cat network-policies/1-ingress-production-deny-all.yaml
kubectl apply -f network-policies/1-ingress-production-deny-all.yaml
# http://web-console ➡️  exception: connect failed
/tmp/mongo users --host mongodb.production.svc.cluster.local --eval 'db.users.find().pretty()'
# http://nosqlclient/ ➡️   Gateway Timeout

#### Allow ingress traffic from ingress controller
# Console Window
cat network-policies/2-ingress-production-allow-traefik-nosqlclient.yaml
kubectl apply -f network-policies/2-ingress-production-allow-traefik-nosqlclient.yaml
# http://nosqlclient/➡️  Ingress works again➡️  But can't connect to database mongodb://mongodb/users


#### Allow ingress traffic on mongo from nosqlclient
# Console Window
cat network-policies/3-ingress-production-allow-nosqlclient-mongo.yaml
kubectl apply -f network-policies/3-ingress-production-allow-nosqlclient-mongo.yaml
# http://nosqlclient/➡️  Connection works again to database mongodb://mongodb/users

#### Allow scraping metrics on mongo from prometheus (monitoring namespace)
# http://promtheus
# Still can scrape mongodb?➡️  Pitfall: Restart prometheus
# Console Window
kubectl -n monitoring delete pod $(kubectl -n monitoring get pods  | awk '/prometheus-server/ {print $1;exit}')
# http://promtheus➡️  No longer possible to scrape
# Console Window 
cat network-policies/4-ingress-production-allow-prometheus-mongodb.yaml
kubectl apply -f network-policies/4-ingress-production-allow-prometheus-mongodb.yaml
# http://promtheus ➡ Scraping possible again

#### Limit ingress to kube-system and monitoring namespaces
# Console Window
kubectl apply -f network-policies/5-ingress-kube-system.yaml
kubectl apply -f network-policies/6-ingress-monitoring.yaml
# http://web-console➡️  no longer possible to query traefik or prometheus from web-console
curl traefik-prometheus.kube-system.svc.cluster.local:9100/metrics
curl prometheus-server.monitoring.svc.cluster.local/graph

#### Limit egress from default and production namespace
# Console Window
kubectl apply -f network-policies/7-egress-default-and-production-namespace.yaml
# http://web-console 
curl https://fastdl.mongodb.org/linux/mongodb-shell-linux-x86_64-debian92-4.4.1.tgz | tar zxv -C /tmp
# ➡️  not possible to download mongodb client

#### Limit egress from other namespaces

# Place actual API Server address in YAML before applying it. See comment in 8-egress-other-namespaces.yaml for more details
ACTUAL_API_SERVER_ADDRESS=$(kubectl get endpoints --namespace default kubernetes --template="{{range .subsets}}{{range .addresses}}{{.ip}}{{end}}{{end}}")
cat network-policies/8-egress-other-namespaces.yaml \
 | sed "s|APISERVER|${ACTUAL_API_SERVER_ADDRESS}/32|" \
 | kubectl apply -f -

kubectl -n monitoring delete pod $(kubectl -n monitoring get pods  | awk '/prometheus-server/ {print $1;exit}')
kubectl rollout restart deployment traefik -n kube-system
# http://promtheus ➡ Scraping possible again
```

