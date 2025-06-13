resource "google_storage_bucket" "storage" {
  name          = var.bucket_name
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  uniform_bucket_level_access = true

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

resource "google_service_account" "storage_account" {
  account_id   = "storage-service-account"
  display_name = "Storage Service Account"
}

resource "google_storage_bucket_iam_member" "storage_admin" {
  bucket = google_storage_bucket.storage.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.storage_account.email}"
}

output "bucket_url" {
  value = google_storage_bucket.storage.url
}

output "storage_service_account_email" {
  value = google_service_account.storage_account.email
}