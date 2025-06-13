module "network" {
  source     = "./modules/network"
  region     = var.region
  project_id = var.project_id
}

module "gke" {
  source          = "./modules/gke"
  zone            = var.zone
  network_name    = module.network.vpc_name
  subnetwork_name = module.network.subnet_name
  project_id      = var.project_id
}

module "compute" {
  source          = "./modules/compute"
  region          = var.region
  subnetwork_name = module.network.subnet_name
  ssh_user        = var.ssh_user
  ssh_public_key  = var.ssh_public_key
  project_id      = var.project_id
  zone            = var.zone
  ssh_key = var.ssh_key
}