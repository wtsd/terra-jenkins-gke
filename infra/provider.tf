terraform {
  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 5.40"

    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.29"

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

