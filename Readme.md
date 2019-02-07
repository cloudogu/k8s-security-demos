# Kubernetes Security Demos

The following demos showcase several Kubernetes security features.

Initially, these demos were developed during the preparation for the 
["3 things every developer should know about K8s security"](https://github.com/cloudogu/k8s-security-3-things) talk by 
[schnatterer](http://github.com/schnatterer/).

Tested to run on Google Kubernetes Engine (GKE) with a local Linux machine.
Should also work on Mac.

1. [Role Based Access Controll (RBAC)](1-rbac/Readme.md)
2. [Network Policies](2-network-policies/Readme.md)
3. [Security Context and Pod Security Policies](3-security-context/Readme.md)

# Prerequisites

In order to use this,  you need to

* setup [`gcloud`](https://cloud.google.com/sdk/install) and `kubectl` and
* set your GKE `zone` and `project` in `config.sh`.

# Setting up the clusters

Each demo is contained in its own sub folder, where each contains a 
 
* `create-clusters.sh` that creates the cluster(s) on GKE to run the demos on and a 
* `README.md` that contains the steps of the demo

Note that the scripts also create entries to your `/etc/hosts`. 
You can delete the cluster and those entries once you're done using the `delete-clusters.sh` script. 

In total 3 Clusters are created with a total of 4 `n1-standard-2` nodes. 
If you left them running for a whole months this would total in about 200$.
However, for just a quick create, demo, delete action this should be much cheaper.
While creating those demos the total cost was about 10$. 

# Credentials

If not otherwise stated, the login credentials for the webapps are

* User: `admin`
* Password: `12345` 

It's a demo after all! 😉

# Cleanup

In order to destroy all cluster, call `delete-clusters.sh`.