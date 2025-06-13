# Google Artifact Registry for storing container images
resource "google_artifact_registry_repository" "container_repo" {
  provider      = google
  location      = var.region
  repository_id = "container-images"
  description   = "Docker container images repository"
  format        = "DOCKER"

  # Optional labels
  labels = {
    environment = "production"
    managed-by  = "terraform"
  }
}

# Output the Artifact Registry repository URL
output "artifact_repository_url" {
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.container_repo.repository_id}"
  description = "The URL of the Artifact Registry repository"
}