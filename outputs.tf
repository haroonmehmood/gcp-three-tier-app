output "cluster_name" {
  description = "Name of the GKE cluster."
  value       = module.gke.cluster_name
}

output "cluster_location" {
  description = "Zone or region the cluster was created in."
  value       = module.gke.cluster_location
}

output "kubectl_credentials_command" {
  description = "Run this to point kubectl at the new cluster."
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --location ${module.gke.cluster_location} --project ${var.project_id}"
}

output "apache_vm_external_ip" {
  description = "Public IP of the standalone Apache VM."
  value       = module.gce.instance_external_ip
}
