terraform {
  
  backend "local" {}
  
  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 3.51.0"
    }
    google-beta  = {
      source  = "hashicorp/google"
      version = "~> 3.51.0"
    }
  }
  required_version = ">= 0.14"
}

provider "google" {
  credentials = file(var.credentials)
  project = var.gce_project
}

# Required for pod_security_policy_config 
provider google-beta {
  credentials = file(var.credentials)
  project = var.gce_project
}

data "google_container_engine_versions" "k8s-security-demo" {
  provider       = google-beta
  location       = var.gce_location
  version_prefix = var.k8s_version_prefix
}

resource "google_container_cluster" "k8s-security-demo-cluster" {
  # Required for pod_security_policy_config 
  provider = google-beta
  name = var.cluster_name

  min_master_version = data.google_container_engine_versions.k8s-security-demo.latest_master_version
  node_version = data.google_container_engine_versions.k8s-security-demo.latest_node_version
  
  location = var.gce_location

  pod_security_policy_config {
    enabled = true
  }

  remove_default_node_pool = true
  initial_node_count = 1

  network_policy {
    # On the nodes
    enabled = true
  }

  addons_config {
    # On the master
    network_policy_config {
      disabled = false
    }
  }

  provisioner "local-exec" {
    # Create entry for cluster in local kubeconfig
    command = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.gce_location} --project ${var.gce_project}"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "kubectl config delete-context gke_${self.project}_${self.location}_${self.name}"
  }
}

resource "google_container_node_pool" "k8s-security-demo-node-pool" {
  location = var.gce_location
  cluster = google_container_cluster.k8s-security-demo-cluster.name
  node_count = var.node_count

  management {
    # Avoid unpleasant surprises during live demos
    auto_upgrade = false
  }

  node_config {
    preemptible = false
    machine_type = var.machine_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      # Grants Read Access to GCR to clusters
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]
  }
}