output "cluster_name" { value = google_container_cluster.primary.name }
output "region" { value = var.region }
output "ip_app" { value = google_compute_global_address.ip_app.address }