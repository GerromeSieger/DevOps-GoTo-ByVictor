# Existing variables from your configuration
variable "zone" {
  description = "The GCP zone to deploy resources"
  type        = string
  default     = "us-central1-a"
}

variable "network_name" {
  description = "The GCP network name"
  type        = string
}

variable "subnetwork_name" {
  description = "The GCP subnetwork name"
  type        = string
}

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

# New variables for Artifact Registry and Cloud Run
variable "region" {
  description = "The GCP region for Artifact Registry and Cloud Run"
  type        = string
  default     = "us-central1" # Should be the region containing your zone
}

variable "service_name" {
  description = "The name of your Cloud Run service"
  type        = string
  default     = "my-application"
}

variable "container_port" {
  description = "The port your container exposes"
  type        = number
  default     = 80
}

variable "container_cpu" {
  description = "CPU allocation for container (e.g., '1000m' for 1 vCPU)"
  type        = string
  default     = "1000m"
}

variable "container_memory" {
  description = "Memory allocation for container (e.g., '512Mi' for 512MB)"
  type        = string
  default     = "512Mi"
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 100
}

variable "container_concurrency" {
  description = "Maximum number of concurrent requests per container instance"
  type        = number
  default     = 80
}

variable "request_timeout" {
  description = "Maximum request timeout in seconds (1-900)"
  type        = number
  default     = 300
}

variable "cpu_throttling" {
  description = "Enable CPU throttling (true/false)"
  type        = bool
  default     = true
}

variable "service_account_email" {
  description = "Service account email for Cloud Run"
  type        = string
  default     = "" # Default to empty string to use compute default service account
}

variable "environment_vars" {
  description = "Environment variables for the Cloud Run service"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to apply to the Cloud Run service"
  type        = map(string)
  default = {
    environment = "production"
    managed-by  = "terraform"
  }
}

variable "allow_public_access" {
  description = "Allow unauthenticated access to the Cloud Run service"
  type        = bool
  default     = true
}

variable "docker_image" {
  description = "Docker image to use"
  type = string
  default = "gerrome/react-site:latest"
}