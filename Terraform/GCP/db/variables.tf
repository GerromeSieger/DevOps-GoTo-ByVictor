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