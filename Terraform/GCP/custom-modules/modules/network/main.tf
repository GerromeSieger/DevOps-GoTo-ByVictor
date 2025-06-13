resource "google_compute_network" "vpc" {
  name                    = "my-custom-vpc"
  auto_create_subnetworks = false
  project                 = var.project_id
}

resource "google_compute_subnetwork" "subnet" {
  name          = "my-custom-subnet"
  ip_cidr_range = "10.0.1.0/24"
  network       = google_compute_network.vpc.id
  region        = var.region
  project       = var.project_id
}

resource "google_compute_firewall" "allow_ssh_http" {
  name    = "allow-ssh-http"
  network = google_compute_network.vpc.name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22", "9000", "3000", "8080", "80", "8111", "8000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["main-vm", "sonar-vm"]
}