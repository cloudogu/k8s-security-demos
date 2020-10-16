variable "gce_project" {
  type = string
  description = "Determines the Google Cloud project to be used"
}

variable "gce_location" {
  type = string
  description = "The GCE location to be used"
}

variable "cluster_name" {
  description = "cluster name inside google cloud project"
}

variable "credentials" {
  description = "Google Service Account JSON used by terraform for authentication"
}

variable "node_count" {
  type = number
  description = "Number of nodes in each cluster"
}

variable "machine_type" {
  description = "Type of VM machines used as cluster nodes"
}

variable "k8s_version_prefix" {
  type = string
  description = "Master and Node version prefix to setup"
}
