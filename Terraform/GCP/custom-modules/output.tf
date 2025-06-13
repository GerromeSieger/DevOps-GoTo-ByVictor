output "cluster_name" {
  value = module.gke.cluster_name
}

output "cluster_endpoint" {
  value = module.gke.cluster_endpoint
}

output "cluster_ca_certificate" {
  value     = module.gke.cluster_ca_certificate
  sensitive = true
}

output "gcloud_connect_command" {
  value = module.gke.gcloud_connect_command
}

output "instance_ip_for_main" {
  value = module.compute.instance_ip_for_main
}

output "ssh_command_for_main" {
  value = module.compute.ssh_command_for_main
}

output "instance_ip_for_sonar" {
  value = module.compute.instance_ip_for_sonar
}

output "ssh_command_for_sonar" {
  value = module.compute.ssh_command_for_sonar
}