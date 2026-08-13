resource "google_compute_network" "three-tier-network" {
  name                    = var.vpc_name
  auto_create_subnetworks = var.auto_create_sub
}

resource "google_compute_subnetwork" "subnetwork_us" {
  ip_cidr_range = var.subnet_us_range
  name          = var.subnet_us_name
  region        = var.region
  network       = google_compute_network.three-tier-network.name

  # Lets instances without a public IP reach Google APIs (gcr.io, logging,
  # monitoring) over internal routing. Free, and required for private nodes.
  private_ip_google_access = true
}

resource "google_compute_firewall" "ssh" {
  name    = var.ssh_firewall_rule_name
  network = google_compute_network.three-tier-network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = var.ssh_source_ranges
}

resource "google_compute_firewall" "allow-vm" {
  name    = var.allow_ingress_firewall_rule_name
  network = google_compute_network.three-tier-network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# Cloud NAT gives outbound internet to instances that have no public IP.
# Only needed when private_nodes = true; without it, GKE nodes cannot pull the
# WordPress and MySQL images from Docker Hub and those pods stay in
# ImagePullBackOff forever. Costs roughly $32/month, so it is off by default.
resource "google_compute_router" "router" {
  count   = var.enable_nat ? 1 : 0
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = google_compute_network.three-tier-network.name
}

resource "google_compute_router_nat" "nat" {
  count                              = var.enable_nat ? 1 : 0
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.router[0].name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
