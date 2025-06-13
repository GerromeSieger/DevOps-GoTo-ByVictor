output "instance_ip_for_main" {
  value = google_compute_instance.main_vm.network_interface[0].access_config[0].nat_ip
}

output "ssh_command_for_main" {
  value = "ssh -i ${var.ssh_key} ${var.ssh_user}@${google_compute_instance.main_vm.network_interface[0].access_config[0].nat_ip}"
}

output "instance_ip_for_sonar" {
  value = google_compute_instance.sonar_vm.network_interface[0].access_config[0].nat_ip
}

output "ssh_command_for_sonar" {
  value = "ssh -i ${var.ssh_key} ${var.ssh_user}@${google_compute_instance.sonar_vm.network_interface[0].access_config[0].nat_ip}"
}