terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 5.40"

    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.0.0"

    }

    helm = {
      source = "hashicorp/helm"
      version = "~> 2.13"

    }
  }
}

provider "google" {
  project     = vars.project_id
  region      = vars.region
}

data "google_client_config" "current" {}

# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/guides/getting-started.html
provider "kubernetes" {
  #host                   = "https://${data.google_container_cluster.my_cluster.endpoint}"
  host                   = google_container_cluster.primary.endpoint
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate)
}

# https://registry.terraform.io/providers/hashicorp/helm/latest/docs
provider "helm" {
    kubernetes = {
        #host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
        host                   = google_container_cluster.primary.endpoint
        token                  = data.google_client_config.provider.access_token
        cluster_ca_certificate = base64decode(
        data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,)
        exec = {
            api_version = "client.authentication.k8s.io/v1beta1"
            command     = "gke-gcloud-auth-plugin"
        }
    }
}
