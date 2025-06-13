variable "ssh_user" {
  description = "SSH username"
}

variable "ssh_public_key" {
  description = "Path to SSH public key file"
}

variable "ssh_key" {
  description = "Path to SSH key file"
}

variable "region" {
  description = "GCP region"
}

variable "subnetwork_name" { # This should be the variable name we use
  description = "Subnet name"
}

variable "project_id" {
  description = "GCP Project ID"
}

variable "zone" {
  description = "GCP zone"
}