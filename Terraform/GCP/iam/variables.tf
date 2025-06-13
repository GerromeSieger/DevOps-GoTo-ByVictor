variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "plucky-furnace-450709-a6"
}

variable "zone" {
  description = "The GCP zone to deploy resources"
  type        = string
  default     = "us-central1-a"
}

variable "region" {
  description = "The GCP region for Artifact Registry and Cloud Run"
  type        = string
  default     = "us-central1"
}

variable "github_repo_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "GerromeSieger"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "Terraform-Scripts"
}

variable "pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
  default     = "github-main-pool"
}

variable "provider_id" {
  description = "Workload Identity Provider ID"
  type        = string
  default     = "github-main-provider"
}

variable "gitlab_group" {
  description = "GitLab group name"
  type        = string
  default = "GerromeSieger"
}

variable "gitlab_project" {
  description = "GitLab project name"
  type        = string
  default = "GerromeApp"
}

variable "pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
  default     = "gitlab-pool"
}

variable "provider_id" {
  description = "Workload Identity Provider ID"
  type        = string
  default     = "gitlab-provider"
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
  default     = "plucky-furnace-450709-a6"
}

variable "project_number" {
  description = "The GCP project number"
  type        = string
  default     = "475219846787"
}

variable "gitlab_username" {
  description = "GitLab username"
  type        = string
  default     = "GerromeSieger"
}

variable "gitlab_project_id" {
  description = "GitLab project ID"
  type        = string
  default     = "67361666"
}

variable "pool_id" {
  description = "Workload Identity Pool ID"
  type        = string
  default     = "gitlab-main-pool"
}

variable "provider_id" {
  description = "Workload Identity Provider ID"
  type        = string
  default     = "gitlab-main-provider"
}

variable "service_account_id" {
  description = "Service Account ID"
  type        = string
  default     = "gitlab-ci-sa"
}

variable "project_path" {
  description = "Gitlab Project Path"
  type = string
  default = "GerromeSieger/GerromeApp"
}