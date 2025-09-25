# Enable required APIs
resource "google_project_service" "container" { service = "container.googleapis.com" }
resource "google_project_service" "compute" { service = "compute.googleapis.com" }
resource "google_project_service" "artifact" { service = "artifactregistry.googleapis.com" }

## Dependency injection
resource "time_sleep" "after_services" {
  depends_on = [
    google_project_service.container,
    google_project_service.compute,
    google_project_service.artifact,
  ]
  create_duration = "60s"
}



## GKE CLUSTER

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_cluster
resource "google_container_cluster" "gke" {
  #name                     = "marcellus-wallace"
  name                     = var.cluster_name
  #location                 = "us-central1-a"
  location                 = var.region
  
  remove_default_node_pool = true

  #initial_node_count = 3
  initial_node_count       = 1

  networking_mode          = "VPC_NATIVE"

  ip_allocation_policy {}

  # https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels
  release_channel { channel = "REGULAR" }

  # Otherwise, terraform destroy doesn't work properly
  deletion_protection = false 

  depends_on = [ time_sleep.after_services ]

}


# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/container_node_pool.html
resource "google_container_node_pool" "default" {
  name       = "default-pool"
  location   = var.region
  cluster    = google_container_cluster.gke.name
  node_count = 1

  node_config {
    machine_type = "e2-medium"
    ## When need more resources:
    #machine_type = "e2-standard-4"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    #service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    # https://cloud.google.com/compute/docs/metadata/predefined-metadata-keys#:~:text=Legacy%20endpoints%20are%20deprecated%2C%20always,%2Dlegacy%2Dendpoints%3DTRUE%20.&text=Sets%20guest%20attributes%20for%20the,data%2C%20or%20low%20frequency%20data.
    metadata     = { disable-legacy-endpoints = "true" }
  }
}


## ARTIFACT REGISTRY REPOSITORY
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/artifact_registry_repository
resource "google_artifact_registry_repository" "ar" {
  location      = var.region
  repository_id = var.artifact_repo
  description   = "Docker Images for CI/CD"
  format        = "DOCKER"

  depends_on = [ time_sleep.after_services ]
}



## IP ADDRESSES FOR CLUSTER AND FOR JENKINS
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address
resource "google_compute_global_address" "ip_app" {
  name = "gke-app-ip"

  depends_on = [ time_sleep.after_services ]
}

resource "google_compute_global_address" "ip_jenkins" {
  name = "gke-jenkins-ip"

  depends_on = [ time_sleep.after_services ]
}



## K8S NAMESPACES
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace
resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
    labels = {
      # https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
    }
  }
}


resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/warn"    = "baseline"
      "pod-security.kubernetes.io/audit"   = "baseline"
    }
  }
  depends_on = [google_container_node_pool.default]
}

resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = "baseline"
      "pod-security.kubernetes.io/warn"    = "baseline"
      "pod-security.kubernetes.io/audit"   = "baseline"
    }
  }
  depends_on = [google_container_node_pool.default]
}

resource "kubernetes_namespace" "apps" {
  metadata {
    name = "apps"
    labels = {
      # https://kubernetes.io/docs/tasks/configure-pod-container/enforce-standards-namespace-labels/
      "app.kubernetes.io/managed-by"            = "terraform"
      "pod-security.kubernetes.io/enforce"      = "baseline"
      "pod-security.kubernetes.io/warn"         = "baseline"
      "pod-security.kubernetes.io/audit"        = "baseline"
    }
  }
}



### JENKINS
## https://dev.to/binoy_59380e698d318/setup-jenkins-on-kubernetes-with-help-of-terraform-gf1

# RBAC
# https://www.jenkins.io/doc/book/installing/kubernetes/
resource "kubernetes_service_account_v1" "jenkins_deployer" {
  metadata {
    name      = "jenkins-deployer"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_cluster_role_v1" "jenkins_deployer" {
  metadata {
    name = "jenkins-deployer"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  rule {
    api_groups = ["", "apps", "batch", "extensions", "networking.k8s.io"]
    resources  = ["deployments","statefulsets","daemonsets","services","pods","pods/log",
                  "configmaps","secrets","ingresses","jobs","cronjobs","namespaces"]
    verbs      = ["get","list","watch","create","update","patch","delete","deletecollection"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles","rolebindings","clusterroles","clusterrolebindings"]
    verbs      = ["get","list","watch","create","update","patch","delete"]
  }
}

resource "kubernetes_cluster_role_binding_v1" "jenkins_deployer" {
  metadata {
    name = "jenkins-deployer"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.jenkins_deployer.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.jenkins_deployer.metadata[0].name
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}


# data "helm_repository" "jenkins" {
#   name = "jenkins"
#   url  = "https://charts.jenkins.io"
# }

# GCE default backend (kube-system)
resource "helm_release" "gce_default_backend" {
  name       = "gce-default-backend"
  namespace  = "kube-system"
  chart      = "${path.module}/charts/gce-default-backend"

  timeout = 1800
  wait    = true
  atomic  = true

  depends_on = [
    google_container_node_pool.default
  ]
}

# BackendConfig for Jekins (/login)
resource "helm_release" "jenkins_backendconfig" {
  name       = "jenkins-backendconfig"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name
  chart      = "${path.module}/charts/jenkins-backendconfig"

  timeout = 1800
  wait    = true
  atomic  = true

  depends_on = [
    google_container_node_pool.default,
    kubernetes_namespace.jenkins
  ]
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  version    = "5.8.91"
  values     = [ file("${path.module}/jenkins-values.yaml") ]

  # Make installs resilient
  timeout            = 1800        # 30m for first image pull
  wait               = true
  atomic             = true
  dependency_update  = true

  force_update       = true
  recreate_pods      = true

  set {
    name  = "controller.ingress.hostName"
    value = var.jenkins_hostname
  }

  depends_on = [
    google_compute_global_address.ip_jenkins,
    kubernetes_namespace.jenkins,
    kubernetes_service_account_v1.jenkins_deployer,
    kubernetes_cluster_role_v1.jenkins_deployer,
    kubernetes_cluster_role_binding_v1.jenkins_deployer,
    helm_release.gce_default_backend,
    helm_release.jenkins_backendconfig
  ]
}