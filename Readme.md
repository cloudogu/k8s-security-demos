![](https://cloudogu.com/assets/blog/2019/Icon_K8Apps-1b648cccc5fe798e6e39e7a2471728e35e0ba6c8491fc281458da5b222a29513.png)

# Kubernetes Security Demos

The following demos showcase several Kubernetes security features.

Initially, these demos were developed during the preparation for the 
["3 things every developer should know about K8s security"](https://github.com/cloudogu/k8s-security-3-things) talk by 
[schnatterer](http://github.com/schnatterer/).

See also our [series of blog posts](#blog-posts) on the topic.

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

# Blog Posts

The examples evolved further while working on an article series called "Kubernetes AppOps Security" published in German Magazin JavaSPEKTRUM. Both English translation and German original can be found on the Cloudogu Blog.

* 05/2019
  * [🇬🇧 Network Policies - Part 1 - Good Practices](https://cloudogu.com/en/blog/k8s-app-ops-part-1)
  * [🇩🇪 Network Policies - Teil 1 - Good Practices](https://cloudogu.com/de/blog/k8s-app-ops-teil-1)
* 06/2019
  * [🇬🇧 Network Policies - Part 2 - Advanced Topics and Tips](https://cloudogu.com/en/blog/k8s-app-ops-part-2)
  * [🇩🇪 Network Policies - Teil 2 - Fortgeschrittene Themen und Tipps](https://cloudogu.com/de/blog/k8s-app-ops-teil-2)
* 01/2020
  * 🇬🇧 Security Context – Part 1: Good Practices
  * 🇩🇪 Security Context – Teil 1: Good Practices
* 02/2020
  * 🇬🇧 Security Context - Background
  * 🇩🇪 Security Context - Hintergründe
* To be continued with PodSecurityPolicies
