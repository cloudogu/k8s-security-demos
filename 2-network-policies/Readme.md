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

```bash
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
curl --output /tmp/mongo.tgz https://downloads.mongodb.org/linux/mongodb-shell-linux-x86_64-3.4.18.tgz && tar xf /tmp/mongo.tgz -C /tmp
/tmp/mongodb-linux-x86_64-3.4.18/bin/mongo users --host mongodb.production.svc.cluster.local --eval 'db.users.find().pretty()'
curl traefik.kube-system.svc.cluster.local:8080/metrics
curl prometheus-server.monitoring.svc.cluster.local/graph

#### Deny all Network Policy
# Console Window
cat network-policies/1-ingress-production-deny-all.yaml
kubectl apply -f network-policies/1-ingress-production-deny-all.yaml
# http://web-console➡️  exception: connect failed
mongodb-linux-x86_64-3.4.18/bin/mongo users --host mongodb.production.svc.cluster.local --eval 'db.users.find().pretty()'
# http://nosqlclient/➡️   Gateway Timeout

#### Allow ingress traffic from ingress controller
# Console Window
cat network-policies/2-ingress-production-allow-traefik-nosqlclient.yaml
kubectl apply -f network-policies/2-ingress-production-allow-traefik-nosqlclient.yaml
# http://nosqlclient/➡️  Ingress works again➡️  But can't connect to database


#### Allow ingress traffic on mongo from nosqlclient
# Console Window
cat network-policies/3-ingress-production-allow-nosqlclient-mongo.yaml
kubectl apply -f network-policies/3-ingress-production-allow-nosqlclient-mongo.yaml
# http://nosqlclient/➡️  Connection works again

#### Allow scraping metrics on mongo from prometheus (monitoring namespace)
# http://promtheus
# Still can scrape mongodb?➡️  Pitfall: Restart prometheus
# Console Window
kubectl -n monitoring delete pod $(kubectl -n monitoring get pods  | awk '/prometheus-server/ {print $1;exit}')
# http://promtheus➡️  No longer possible to scrape
# Console Window 
cat network-policies/4-ingress-production-allow-prometheus-mongodb.yaml
kubectl apply -f network-policies/4-ingress-production-allow-prometheus-mongodb.yaml
# http://promtheus➡️  Scraping possible again

#### Limit ingress to kube-system and monitoring namespaces
# Console Window
kubectl apply -f network-policies/5-ingress-kube-system.yaml
kubectl apply -f network-policies/6-ingress-monitoring.yaml
# http://web-console➡️  no longer possible to query traefik or prometheus from web-console
curl traefik.kube-system.svc.cluster.local:8080/metrics
curl prometheus-server.monitoring.svc.cluster.local/graph

#### Limit egress from default and production namespace
# Console Window
kubectl apply -f network-policies/7-egress-default-and-production-namespace.yaml
# http://web-console 
curl --output mongo.tgz https://downloads.mongodb.org/linux/mongodb-shell-linux-x86_64-3.4.18.tgz && tar xf mongo.tgz
#➡️  not possible to download mongodb client
# http://nosqlclient/
#➡️  on subscription is not possible 
```

