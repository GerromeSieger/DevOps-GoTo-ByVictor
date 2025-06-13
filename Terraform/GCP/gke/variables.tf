variable "project_id" {
  description = "GCP Project ID"
  default     = "plucky-furnace-450709-a6"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "ssh_public_key" {
  description = "SSH public key for instance access"
  type        = string
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "ubuntu"
}

variable "network_name" {
  description = "The network name for the gke cluster"
  type        = string
  default     = "default"
}

variable "subnetwork_name" {
  description = "The subnetwork name for the gke cluster"
  type        = string
  default     = "default"
}

variable "bucket_name" {
  description = "Name of the GCS bucket"
  type        = string
  default     = "gerromeunekwubucket"
}