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

variable "ssh_key" {
  description = "Path to SSH key file"
}

variable "network_name" {
  description = "The network name for the gke cluster"
  type        = string
}

variable "subnetwork_name" {
  description = "The subnetwork name for the gke cluster"
  type        = string
}

variable "bucket_name" {
  description = "Name of the GCS bucket"
  type        = string
}

variable "instance_name" {
  description = "The name of the Cloud SQL instance"
  type        = string
}

variable "db_name" {
  description = "The name of the database to create"
  type        = string
}

variable "db_user" {
  description = "The name of the database user"
  type        = string
}

variable "db_password" {
  description = "The password for the database user"
  type        = string
  sensitive   = true
}