resource "google_container_cluster" "primary" {
  name                     = "my-gke-cluster"
  location                 = var.zone
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network_name
  subnetwork = var.subnetwork_name

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = "10.100.0.0/16"
    services_ipv4_cidr_block = "10.101.0.0/16"
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "my-node-pool"
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = 2

  node_config {
    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env = "production"
    }

    tags = ["gke-node"]

    # Add explicit resource_labels configuration
    resource_labels = {}
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  # Expanded ignore_changes block
  lifecycle {
    ignore_changes = [
      node_count,
      node_config[0].machine_type,
      node_config[0].labels,
      node_config[0].tags,
      node_config[0].resource_labels,
      node_config[0].kubelet_config,
      management,
    ]
  }
}

# Outputs
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

# Output the command to connect to the cluster
output "gcloud_connect_command" {
  value = <<EOT
  gcloud container clusters get-credentials ${google_container_cluster.primary.name} \
    --zone ${var.zone} \
    --project ${var.project_id}
  EOT
}