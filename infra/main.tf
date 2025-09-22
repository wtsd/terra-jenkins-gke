## GKE CLUSTER

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
resource "google_container_cluster" "primary" {
  #name               = "marcellus-wallace"
  name               = var.cluster_name
  #location           = "us-central1-a"
  location           = var.region
  #initial_node_count = 3
  initial_node_count = 1

  node_config {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    labels = {
      env = "cicd"
    }
    tags = ["env", "cicd"]
  }
  timeouts {
    create = "30m"
    update = "40m"
  }

  ### Network information
  networking_mode = "VPC_NATIVE"
  network         = var.network
  subnetwork      = var.subnetwork

  remove_default_node_pool = true

  ip_allocation_policy {}
}


# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool.html
resource "google_container_node_pool" "np" {
  name       = "default-pool"
  cluster    = google_container_cluster.primary.id
  location   = var.region
  node_count = 1

  node_config {
    preemptible  = true
    machine_type = "e2-medium"
    ## When need more resources:
    #machine_type = "e2-standard-4"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}


## ARTIFACT REGISTRY REPOSITORY
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository
resource "google_artifact_registry_repository" "ar" {
  location      = var.region
  repository_id = var.artifact_repo
  description   = "Docker Images for CI/CD"
  format        = "DOCKER"
}



## IP ADDRESSES FOR CLUSTER AND FOR JENKINS
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address
resource "google_compute_global_address" "ip_app" {
  name = "gke-app-ip"
}

resource "google_compute_global_address" "ip_jenkins" {
  name = "gke-jenkins-ip"
}



## K8S NAMESPACES
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace
resource "kubernetes_namespace" "jenkins" {
  metadata {
    annotations = {
      name = "jenkins"
    }

    labels = {
      app = "jenkins"
    }

    name = "jenkins"
  }
}

resource "kubernetes_namespace" "apps" {
  metadata {
    annotations = {
      name = "apps"
    }

    labels = {
      app = "workers"
    }

    name = "apps"
  }
}


