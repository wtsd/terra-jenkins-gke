# GCP:
variable "project_id" { type = string }
variable "region" {
  type = string
  default = "us-central1"
}

variable "cluster_name" {
  type    = string
  default = "ci-gke"
}

# DNS hostnames: control—point them to the Terraform outputs (IPs) after apply
variable "jenkins_hostname" {
  type = string
  default = "jenkins.example.com"
}
variable "app_hostname" {
  type = string
  default = "app.example.com"
}

variable "artifact_repo" {
  type = string
  default = "apps"
}
