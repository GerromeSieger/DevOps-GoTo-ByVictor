variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  sensitive   = true
  type        = string
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
}