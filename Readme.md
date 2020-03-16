# Kubernetes Security Demos

The following demos showcase several Kubernetes security features.

Initially, these demos were developed during the preparation for the 
["3 things every developer should know about K8s security"](https://github.com/cloudogu/k8s-security-3-things) talk by 
[schnatterer](http://github.com/schnatterer/).

Tested to run on Google Kubernetes Engine (GKE) with a local Linux machine.
Should also work on Mac.

1. [Role Based Access Controll (RBAC)](1-rbac/Readme.md)
2. [Network Policies](2-network-policies/Readme.md)
3. [Security Context](3-security-context/Readme.md)
4. [Pod Security Policies](4-pod-security-policies/Readme.md)

# Prerequisites

In order to use this,  you need to

* setup [`gcloud`](https://cloud.google.com/sdk/install) and `kubectl` and
* set your GKE `ZONE` and `PROJECT` in `config.sh`  
  (alternatively, you can set `ZONE` and `PROJECT` env vars).

Note that you can also set `CLUSTER_VERSION` (like `1.11`) and  `MACHINE_TYPE` (like `n1-standard-2`).
From time to time GKE drops support for older cluster versions so you might need to set a newer one, if the one in 
`config.sh` is no longer supported at the time of execution. 

# Setting up the clusters

Each demo is contained in its own sub folder, where each contains a 
 
* `create-clusters.sh` that creates the cluster(s) on GKE to run the demos on and a 
* `README.md` that contains the steps of the demo

Note that the scripts also create entries to your `/etc/hosts`.
 
You can delete the cluster and those entries once you're done using the `delete-clusters.sh` script. 

All Demos run inside the same cluster, except the RBAC Demo that requires another one (without RBAC). 

For just a quick create, demo, delete action the cost should be < 10$.
The total infra cost for initially creating these demos was about 10$. 

# Credentials

If not otherwise stated, the login credentials for the webapps are

* User: `admin`
* Password: `12345` 

It's a demo after all! 😉

# Cleanup

In order to destroy all cluster, call `delete-clusters.sh`.