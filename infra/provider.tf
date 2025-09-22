terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.40"

    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29"

    }

    helm = {
      source = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "google_client_config" "default" {}

# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/guides/getting-started.html
provider "kubernetes" {
  #host                   = "https://${data.google_container_cluster.my_cluster.endpoint}"
  host                   = google_container_cluster.primary.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
}

## https://registry.terraform.io/providers/hashicorp/helm/latest/docs
provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.gke.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.gke.master_auth[0].cluster_ca_certificate)
  }
}
