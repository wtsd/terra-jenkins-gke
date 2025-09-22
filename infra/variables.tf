# GCP:
variable "project_id" { type = string }
variable "region" { type = string }
variable "zone" { type = string }

variable "cluster_name" {
  type    = string
  default = "ci-gke"
}
variable "network" {
  type    = string
  default = "default"
}
variable "subnetwork" {
  type    = string
  default = "default"
}

#variable "artifact_repo" { type = string default = "apps" }

variable "app_hostname" {
  type    = string
  default = "app.example.com"
}