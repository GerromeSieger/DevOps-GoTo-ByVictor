# Create the service account for GitLab CI
resource "google_service_account" "gitlab_ci_sa" {
  account_id   = var.service_account_id
  display_name = "GitLab CI/CD Service Account"
  description  = "Service account for GitLab CI/CD pipeline"
}

# Create the Workload Identity Pool
resource "google_iam_workload_identity_pool" "gitlab_pool" {
  workload_identity_pool_id = var.pool_id
  display_name              = "GitLab project ID ${var.gitlab_project_id}"
  description               = "Identity pool for GitLab CI/CD"
  disabled                  = false
}

# Create the Workload Identity Provider
resource "google_iam_workload_identity_pool_provider" "gitlab_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.gitlab_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitLab project ID ${var.gitlab_project_id}"
  description                        = "Workload Identity Provider for GitLab CI/CD"
  disabled                           = false
  
  attribute_mapping = {
    "google.subject"           = "assertion.sub"
    "attribute.namespace_path" = "assertion.namespace_path"
    "attribute.project_path"   = "assertion.project_path"
    "attribute.project_id"     = "assertion.project_id"
    "attribute.ref"            = "assertion.ref"
    "attribute.ref_type"       = "assertion.ref_type"
  }

  attribute_condition = "attribute.project_path.startsWith('${var.project_path}')"
  
  oidc {
      issuer_uri = "https://gitlab.com"
  }
}

# Grant the service account container developer role
resource "google_project_iam_member" "gitlab_sa_container_developer" {
  project = var.project_id
  role    = "roles/container.developer"
  member  = "serviceAccount:${google_service_account.gitlab_ci_sa.email}"
}

resource "google_project_iam_member" "gitlab_sa_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.gitlab_ci_sa.email}"
}

# Grant the service account container viewer role for cluster access
resource "google_project_iam_member" "gitlab_sa_container_viewer" {
  project = var.project_id
  role    = "roles/container.clusterViewer"
  member  = "serviceAccount:${google_service_account.gitlab_ci_sa.email}"
}

# Grant the service account GKE admin role for full cluster management
resource "google_project_iam_member" "gitlab_sa_gke_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.gitlab_ci_sa.email}"
}

# Allow the GitLab Workload Identity Pool to impersonate the service account
resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.gitlab_ci_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gitlab_pool.workload_identity_pool_id}/attribute.project_id/${var.gitlab_project_id}",
    # Add this line to allow specific user authentication pattern seen in error logs
    "principal://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gitlab_pool.workload_identity_pool_id}/subject/usr:${var.gitlab_username}/*"
  ]
}

# Outputs
output "workload_identity_provider" {
  description = "The Workload Identity Provider resource name to use in GitLab CI configuration"
  value       = "projects/${var.project_number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gitlab_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.gitlab_provider.workload_identity_pool_provider_id}"
}

output "service_account_email" {
  description = "The Service Account email to use in GitLab CI configuration"
  value       = google_service_account.gitlab_ci_sa.email
}

output "principal_set_for_project" {
  description = "The principal set string for the GitLab project"
  value       = "principalSet://iam.googleapis.com/projects/${var.project_number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.gitlab_pool.workload_identity_pool_id}/attribute.project_id/${var.gitlab_project_id}"
}