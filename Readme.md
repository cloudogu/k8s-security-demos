![](https://cloudogu.com/assets/blog/2019/Icon_K8Apps-1b648cccc5fe798e6e39e7a2471728e35e0ba6c8491fc281458da5b222a29513.png)

# Kubernetes Security Demos

The following demos showcase several Kubernetes security features.

Initially, these demos were developed during the preparation for some talks on [Kubernetes appOps Security](https://github.com/cloudogu/k8s-appops-security-talks) and our [K8s application security training](https://cloudogu.com/en/trainings/).

See also our [series of blog posts](#blog-posts) on the topic.

Tested to run on Google Kubernetes Engine (GKE) with a local Linux machine.  
Should also work on Mac.  
Should run on all clusters that support NetworkPolicies and PodSecurityPolicies.


1. ~~Role Based Access Controll (RBAC)~~ - RBAC has now been default for years. 
A showcase for the downsides of ABAC seems obsolete. 
If you're interested check [git history](https://github.com/cloudogu/k8s-security-demos/tree/b94aa0a94358cc04f3f1beed80f755ac14b994da).
2. [Network Policies](2-network-policies/Readme.md)
3. [Security Context](3-security-context/Readme.md)
4. [Pod Security Policies](4-pod-security-policies/Readme.md)

# Running the demos

Each demo is contained in its own sub folder, where each contains a 
 
* `apply.sh` that deploys the applications required for the demos and
* `README.md` that contains the steps of the demo

Note that the scripts also create entries to your `/etc/hosts`.

All Demos run inside the same cluster. Before running make sure to have your `kubeconfig` set to a non-productive cluster.
If you want, you can set one up on your GKE account using the script inside this repo. 
See [Setting up the clusters](#setting-up-the-clusters).

# Credentials

If not otherwise stated, the login credentials for the webapps are

* User: `admin`
* Password: `12345` 

It's a demo after all! 😉

# Blog Posts

The examples evolved further while working on an article series called "Kubernetes AppOps Security" published in German Magazin JavaSPEKTRUM. Both English translation and German original can be found on the Cloudogu Blog.

* 05/2019
  * [🇬🇧 Network Policies - Part 1 - Good Practices](https://cloudogu.com/en/blog/k8s-app-ops-part-1)
  * [🇩🇪 Network Policies - Teil 1 - Good Practices](https://cloudogu.com/de/blog/k8s-app-ops-teil-1)
* 06/2019
  * [🇬🇧 Network Policies - Part 2 - Advanced Topics and Tips](https://cloudogu.com/en/blog/k8s-app-ops-part-2)
  * [🇩🇪 Network Policies - Teil 2 - Fortgeschrittene Themen und Tipps](https://cloudogu.com/de/blog/k8s-app-ops-teil-2)
* 01/2020
  * [🇬🇧 Security Context – Part 1: Good Practices](https://cloudogu.com/en/blog/k8s-app-ops-part-3-security-context-1)
  * [🇩🇪 Security Context – Teil 1: Good Practices](https://cloudogu.com/de/blog/k8s-app-ops-teil-3-security-context-1)
* 02/2020
  * [🇬🇧 Security Context - Background](https://cloudogu.com/en/blog/k8s-app-ops-part-4-security-context-2)
  * [🇩🇪 Security Context - Hintergründe](https://cloudogu.com/de/blog/k8s-app-ops-teil-4-security-context-2)
* To be continued with PodSecurityPolicies

# Setting up the clusters

This demos should run on most kubernetes clusters that have support for NetworkPolicies and PodSecurityPolicies.

This repo also features setting up a defined environment Google Kubernetes engine. 
You can set it up using [createCluster.sh](createCluster.sh).  
It uses terraform to roll out the clusters. If you prefer a bash-only variant, check [git history](https://github.com/cloudogu/k8s-security-demos/tree/b94aa0a94358cc04f3f1beed80f755ac14b994da).

In order to use the script

* set your GKE `ZONE` and `PROJECT` in `config.sh`  
  (alternatively, you can set these properties via env vars).  
  Note that you can also set `CLUSTER_VERSION` (like `1.11`) and  `MACHINE_TYPE` (like `n1-standard-2`).
  From time to time GKE drops support for older cluster versions, so you might need to set a newer one, if the one in 
  `config.sh` is no longer supported at the time of execution. 
* set up a service account on GKE that allows terraform to do the setup
```shell script
source config.sh
SA=terraform-cluster

# Create SA
gcloud iam service-accounts create ${SA} --display-name ${SA} --project ${PROJECT}

# Authorize (maybe roles/container.admin is enough?) 
gcloud projects add-iam-policy-binding ${PROJECT} \
  --member serviceAccount:${SA}@${PROJECT}.iam.gserviceaccount.com --role=roles/editor

# Export credentials
gcloud iam service-accounts keys create \
  --iam-account serviceAccount:${SA}@${PROJECT}.iam.gserviceaccount.com terraform/account.json
``` 
* Have terraform installed (should work with 0.12 and 0.13)
* Call `./create Cluster.sh`
* Terraform will ask for confirmation before executing. 

## Deleting clusters 

You can delete the cluster and entries to `/etc/hosts` once you're done using the `delete-clusters.sh` script. 

## Costs 

For just a quick create, demo, delete action the cost should be < 10$.
The total infra cost for initially creating these demos was about 10$. 