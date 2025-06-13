resource "google_project_service" "sql_admin_api" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_sql_database_instance" "postgres" {
  name                = var.instance_name
  database_version    = "POSTGRES_16"
  region              = "us-central1"
  deletion_protection = false

  settings {
    tier    = "db-custom-4-16384"
    edition = "ENTERPRISE"

    disk_size = 100
    disk_type = "PD_SSD"

    availability_type = "ZONAL"

    backup_configuration {
      enabled                        = true
      point_in_time_recovery_enabled = true
      backup_retention_settings {
        retained_backups = 7
      }
    }

    ip_configuration {
      ipv4_enabled = true
    }
  }

  depends_on = [google_project_service.sql_admin_api]
}

resource "google_sql_database" "database" {
  name     = var.db_name
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "user" {
  name     = var.db_user
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}

output "instance_connection_name" {
  value = google_sql_database_instance.postgres.connection_name
}

output "instance_ip_address" {
  value = google_sql_database_instance.postgres.public_ip_address
}