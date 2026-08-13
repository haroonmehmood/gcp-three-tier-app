output "vpc_name" {
  value = google_compute_network.three-tier-network.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnetwork_us.name
}