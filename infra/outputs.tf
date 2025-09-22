output "cluster_name" { value = google_container_cluster.gke.name }
output "region"       { value = var.region }
output "jenkins_ip"   { value = google_compute_global_address.ip_jenkins.address }
output "app_ip"       { value = google_compute_global_address.ip_app.address }
