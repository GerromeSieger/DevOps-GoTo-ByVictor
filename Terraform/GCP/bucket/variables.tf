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

variable "bucket_name" {
  description = "Name of the GCS bucket"
  type        = string
  default     = "gerromeunekwubucket"
}