locals {
  service_account_id  = "terraform-github-sa"
  service_account_email = "${local.service_account_id}@${var.project_id}.iam.gserviceaccount.com"
}

provider "google" {
  project = var.project_id
}

# Create the Workload Identity Pool
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions"
  disabled                  = false
}

# Create the Workload Identity Provider
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "Github pool provider"
  description                        = "My workload pool provider description"
  disabled                           = false
  
  attribute_mapping = {
    "google.subject"         = "assertion.sub"
    "attribute.repository"   = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }
  
  attribute_condition = "attribute.repository_owner=='${var.github_repo_owner}'"
  
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Create the Service Account
resource "google_service_account" "github_sa" {
  account_id   = local.service_account_id
  display_name = "Terraform GitHub Actions Service Account"
  description  = "Service account for GitHub Actions to deploy Terraform"
}

# Grant editor role to the Service Account
resource "google_project_iam_member" "github_sa_editor" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.github_sa.email}"
}

# Allow the GitHub Workload Identity Pool to impersonate the Service Account
resource "google_service_account_iam_binding" "workload_identity_binding" {
  service_account_id = google_service_account.github_sa.name
  role               = "roles/iam.workloadIdentityUser"
  members = [
    "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/${var.github_repo_owner}/${var.github_repo}"
  ]
}

# Get project details
data "google_project" "project" {
  project_id = var.project_id
}

# Output the Workload Identity Provider resource name (for GitHub Actions workflow)
output "workload_identity_provider" {
  description = "The Workload Identity Provider resource name to use in GitHub Actions"
  value       = "projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/providers/${google_iam_workload_identity_pool_provider.github_provider.workload_identity_pool_provider_id}"
}

output "service_account_email" {
  description = "The Service Account email to use in GitHub Actions"
  value       = google_service_account.github_sa.email
}

output "github_repository_attribute" {
  description = "The full GitHub repository attribute"
  value       = "principalSet://iam.googleapis.com/projects/${data.google_project.project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github_pool.workload_identity_pool_id}/attribute.repository/${var.github_repo_owner}/${var.github_repo}"
}

output "project_number" {
  description = "The GCP project number"
  value       = data.google_project.project.number
}