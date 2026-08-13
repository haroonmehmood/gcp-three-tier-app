data "google_project" "project" {}

resource "google_container_cluster" "gke_cluster" {
  name       = var.cluster_name
  network    = var.cluster_network
  subnetwork = var.subnetwork

  # A zone (e.g. us-central1-a) makes this a ZONAL cluster: node counts below
  # are the total. A region (e.g. us-central1) makes it REGIONAL and multiplies
  # every node count by the number of zones in that region.
  location = var.cluster_location

  # Provider v5+ refuses `terraform destroy` while this is true. Keep it false
  # so the cluster can actually be torn down when you are done.
  deletion_protection = false

  ip_allocation_policy {}

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.control_network
      display_name = "displayname"
    }
  }

  dynamic "private_cluster_config" {
    for_each = var.private_nodes ? [1] : []
    content {
      enable_private_nodes    = var.private_nodes
      enable_private_endpoint = var.enable_private_endpoint
      master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    }
  }

  dynamic "node_pool" {
    for_each = var.node_pools
    content {
      name               = node_pool.value.name
      initial_node_count = node_pool.value.initial_node_count

      management {
        auto_repair  = node_pool.value.auto_repair
        auto_upgrade = node_pool.value.auto_upgrade
      }

      autoscaling {
        min_node_count = node_pool.value.min_node_count
        max_node_count = node_pool.value.max_node_count
      }

      node_config {
        image_type      = node_pool.value.image_type
        disk_size_gb    = node_pool.value.disk_size_gb
        preemptible     = node_pool.value.preemptible
        machine_type    = node_pool.value.machine_type
        labels          = node_pool.value.labels
        service_account = "${data.google_project.project.number}-compute@developer.gserviceaccount.com"
        metadata        = node_pool.value.metadata
        oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
      }
    }
  }
}
