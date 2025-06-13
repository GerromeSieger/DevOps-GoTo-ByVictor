resource "google_compute_instance" "vm_instance" {
  name         = "web-server"
  machine_type = "e2-standard-2"
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

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install fish docker.io -y
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo chmod 666 /var/run/docker.sock
    sudo systemctl start docker
    sudo systemctl enable docker
  EOF  
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

  metadata_startup_script = <<-EOF
    #!/bin/bash
    sudo apt update -y
    sudo apt install fish docker.io -y
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    sudo chmod 666 /var/run/docker.sock
    sudo systemctl start docker
    sudo systemctl enable docker
  EOF  
}
# outputs.tf
output "instance_ip" {
  description = "The public IP address of the instance"
  value       = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}

output "instance_ip_for_sonar" {
  description = "The public IP address of the sonar instance"
  value       = google_compute_instance.vm_instance2.network_interface[0].access_config[0].nat_ip
}

output "ssh_command" {
  description = "Command to SSH into the instance"
  value       = "ssh -i ${var.ssh_key} ${var.ssh_user}@${google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip}"
}

output "ssh_command_for_sonar" {
  description = "Command to SSH into the instance"
  value       = "ssh -i ${var.ssh_key} ${var.ssh_user}@${google_compute_instance.vm_instance2.network_interface[0].access_config[0].nat_ip}"
}