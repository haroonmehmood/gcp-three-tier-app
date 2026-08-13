module "network" {
  source                 = "./modules/network"
  auto_create_sub        = var.auto_create_sub
  vpc_name               = var.vpc_name
  subnet_us_range        = var.subnet_us_range
  subnet_us_name         = var.subnet_us_name
  region                 = var.region
  ssh_firewall_rule_name = var.ssh_firewall_rule_name
  ssh_source_ranges      = var.ssh_source_ranges
  enable_nat             = var.enable_nat
}

module "gke" {
  source                  = "./modules/gke"
  cluster_name            = var.cluster_name
  enable_private_endpoint = var.enable_private_endpoint
  node_pools              = var.node_pools
  project_id              = var.project_id
  region                  = var.region
  cluster_location        = var.cluster_location
  subnetwork              = module.network.subnet_name
  cluster_network         = module.network.vpc_name
  zone                    = var.zone
  master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  min_master_version      = var.min_master_version
  private_nodes           = var.private_nodes
  control_network         = var.control_network
}

module "gce" {
  source          = "./modules/gce"
  instance_image  = var.instance_image
  instance_name   = var.instance_name
  instance_type   = var.instance_type
  network_name    = module.network.vpc_name
  zone            = var.zone
  subnetwork_name = module.network.subnet_name
}
