# Enable required APIs
resource "google_project_service" "container" { service = "container.googleapis.com" }
resource "google_project_service" "artifact" { service = "artifactregistry.googleapis.com" }
resource "google_project_service" "compute" { service = "compute.googleapis.com" }


## GKE CLUSTER

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
resource "google_container_cluster" "primary" {
  #name               = "marcellus-wallace"
  name = var.cluster_name
  #location           = "us-central1-a"
  location = var.region
  #initial_node_count = 3
  initial_node_count = 1

  node_config {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    #service_account = google_service_account.default.email
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
    #service_account = google_service_account.default.email
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

#resource "google_compute_global_address" "ip_jenkins" {
#  name = "gke-jenkins-ip"
#}



## K8S NAMESPACES
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace
resource "kubernetes_namespace" "jenkins" {
  metadata {
    annotations = {
      name = "jenkins"
    }

    labels = {
      app                                  = "jenkins"
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/warn"    = "baseline"
      "pod-security.kubernetes.io/audit"   = "baseline"
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
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/warn"    = "baseline"
      "pod-security.kubernetes.io/audit"   = "baseline"
    }

    name = "apps"
  }
}



### JENKINS
## https://dev.to/binoy_59380e698d318/setup-jenkins-on-kubernetes-with-help-of-terraform-gf1
#resource "helm_release" "jenkins" {
#  name       = "jenkins"
#  repository = "https://charts.jenkins.io"
#  chart      = "jenkins"
#  version    = "5.8.91"
#
#  # Get namespace from above
#  namespace = kubernetes_namespace.jenkins.metadata[0].name
#
# #set {
#  #  name  = "controller.servicePort"
#  #  value = "8080"
##  #}
#  #
#  #set {
#  #  name  = "controller.admin.password"
#  #  value = "admin"
#  #}
#
#  timeout = 600
# 
#  depends_on = [google_compute_global_address.ip_jenkins, kubernetes_namespace.jenkins]
#} 

