resource "google_compute_instance" "main_vm" {
  name         = "main-vm"
  machine_type = "e2-medium"
  tags         = ["main-vm"]
  project      = var.project_id
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    subnetwork = var.subnetwork_name
    subnetwork_project = var.project_id
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }
}

resource "google_compute_instance" "sonar_vm" {
  name         = "sonar-vm"
  machine_type = "e2-medium"
  tags         = ["sonar-vm"]
  project      = var.project_id
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    subnetwork = var.subnetwork_name
    subnetwork_project = var.project_id
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }
}