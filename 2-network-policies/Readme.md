# NetworkPolicy Demo

![Clusters, Namespaces, Pods and allowed routes](http://www.plantuml.com/plantuml/svg/dOzFQy904CNl-oc6zE0fD2gev514GNeGyI3qK3niigCisTr9zmzIYj-zcvYIOFySkgUPUVD-RtRfFBS-QCLS9KtDBTSWZKTxuYN21mDOyR8wMmf6h4cHXOV9b4-5Q1Io0cqt7SzcYuLWLpO0SMlfqaA6rhkbadHD1et_Hnh0XeplPflsDN3M_o1vFXps2N07snLZXaGShLLmKOST-WlP2lQaP2dH9V62YApZ2VmSztPSeuiTmgWA1QRkFThqg5c3-5uFbkD9LiU6ddHDSfEsgoEawLE_4yVNt-02JpmetuDVi80r6KSAZtTHBNIeGmuNBDBorkQBxA-asf88fPTa-Z13xasLIgBnFuODzHWsQFDfbcNV89rDapcJA1fBL-QFNyLadetdxPrNjaGZWbQV)

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
gcloud container clusters get-credentials ${CLUSTER2} \
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
# http://web-console ➜ exception: connect failed
mongodb-linux-x86_64-3.4.18/bin/mongo users --host mongodb.production.svc.cluster.local --eval 'db.users.find().pretty()'
# http://nosqlclient/ ➜  Gateway Timeout

#### Allow ingress traffic from ingress controller
# Console Window
cat network-policies/2-ingress-production-allow-traefik-nosqlclient.yaml
kubectl apply -f network-policies/2-ingress-production-allow-traefik-nosqlclient.yaml
# http://nosqlclient/ ➜ Ingress works again ➜ But can't connect to database


#### Allow ingress traffic on mongo from nosqlclient
# Console Window
cat network-policies/3-ingress-production-allow-nosqlclient-mongo.yaml
kubectl apply -f network-policies/3-ingress-production-allow-nosqlclient-mongo.yaml
# http://nosqlclient/ ➜ Connection works again

#### Allow scraping metrics on mongo from prometheus (monitoring namespace)
# http://promtheus
# Still can scrape mongodb? ➜ Pitfall: Restart prometheus
# Console Window
kubectl -n monitoring delete pod $(kubectl -n monitoring get pods  | awk '/prometheus-server/ {print $1;exit}')
# http://promtheus ➜ No longer possible to scrape
# Console Window 
cat network-policies/4-ingress-production-allow-prometheus-mongodb.yaml
kubectl apply -f network-policies/4-ingress-production-allow-prometheus-mongodb.yaml
# http://promtheus ➜ Scraping possible again

#### Limit ingress to kube-system and monitoring namespaces
# Console Window
kubectl apply -f network-policies/5-ingress-kube-system.yaml
kubectl apply -f network-policies/6-ingress-monitoring.yaml
# http://web-console ➜ no longer possible to query traefik or prometheus from web-console
curl traefik.kube-system.svc.cluster.local:8080/metrics
curl prometheus-server.monitoring.svc.cluster.local/graph

#### Limit egress from default and production namespace
# Console Window
kubectl apply -f network-policies/7-egress-default-and-production-namespace.yaml
# http://web-console 
curl --output mongo.tgz https://downloads.mongodb.org/linux/mongodb-shell-linux-x86_64-3.4.18.tgz && tar xf mongo.tgz
# ➜ not possible to download mongodb client
# http://nosqlclient/
# ➜ on subscription is not possible 
```

