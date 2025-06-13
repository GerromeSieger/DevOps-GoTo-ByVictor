resource "google_compute_instance" "vm_instance" {
  name         = "web-server"
  machine_type = "e2-medium"
  tags         = ["web-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.name
    access_config {
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }
}

resource "google_compute_instance" "vm_instance2" {
  name         = "sonarqube"
  machine_type = "e2-medium"
  tags         = ["sonarqube"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet.name
    access_config {
    }
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key)}"
  }
}
# outputs.tf
output "instance_ip" {
  description = "The public IP address of the instance"
  value       = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "Command to SSH into the instance"
  value       = "ssh ${var.ssh_user}@${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip}"
}