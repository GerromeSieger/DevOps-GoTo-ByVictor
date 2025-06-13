# Cloud Run service
resource "google_cloud_run_service" "default" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      containers {
      #  image = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.container_repo.repository_id}/${var.service_name}:latest"
        image = var.docker_image
        resources {
          limits = {
            cpu    = var.container_cpu
            memory = var.container_memory
          }
        }

        # Environment variables (optional)
        dynamic "env" {
          for_each = var.environment_vars
          content {
            name  = env.key
            value = env.value
          }
        }

        # Container port (optional - Cloud Run automatically detects the port)
        ports {
          container_port = var.container_port
        }
      }

      # Service account that will run the container (optional)
      service_account_name = var.service_account_email

      # Container concurrency (how many requests each instance can handle simultaneously)
      container_concurrency = var.container_concurrency

      # Timeout for requests
      timeout_seconds = var.request_timeout
    }

    metadata {
      annotations = {
        # Auto-scaling settings
        "autoscaling.knative.dev/minScale" = var.min_instances
        "autoscaling.knative.dev/maxScale" = var.max_instances

        # Optional: CPU throttling
        "run.googleapis.com/cpu-throttling" = var.cpu_throttling
      }

      labels = var.labels
    }
  }

  # Traffic configuration (allows gradual rollout of new versions)
  traffic {
    percent         = 100
    latest_revision = true
  }

  # Allow unauthenticated access (optional, set to false for private services)
  autogenerate_revision_name = true
}

# IAM policy to make the Cloud Run service publicly accessible 
# (You can remove this if you want to make the service private)
# data "google_iam_policy" "noauth" {
#   binding {
#     role = "roles/run.invoker"
#     members = [
#       "allUsers",
#     ]
#   }
# }

# resource "google_cloud_run_service_iam_policy" "noauth" {
#   count    = var.allow_public_access ? 1 : 0
#   location = google_cloud_run_service.default.location
#   project  = google_cloud_run_service.default.project
#   service  = google_cloud_run_service.default.name

#   policy_data = data.google_iam_policy.noauth.policy_data
# }

# Outputs
output "cloud_run_url" {
  value       = google_cloud_run_service.default.status[0].url
  description = "The URL of the deployed Cloud Run service"
}

output "cloud_run_name" {
  value       = google_cloud_run_service.default.name
  description = "The name of the Cloud Run service"
}

output "cloud_run_location" {
  value       = google_cloud_run_service.default.location
  description = "The location of the Cloud Run service"
}