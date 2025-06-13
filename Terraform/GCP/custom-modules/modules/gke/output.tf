output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  value     = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive = true
}

output "gcloud_connect_command" {
  value = <<EOT
  gcloud container clusters get-credentials ${google_container_cluster.primary.name} \
    --zone ${var.zone} \
    --project ${var.project_id}
  EOT
}