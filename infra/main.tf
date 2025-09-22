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

