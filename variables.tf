variable "project_id" {
  description = "- (Required)  Google account project id."
}
variable "region" {
  type        = string
  description = "- (Required) Google region where the cluster will be deployed."
}

variable "vpc_name" {
  type        = string
  description = "- (Required) Name of the VPC where the cluster will be deployed."
}

variable "auto_create_sub" {
  type        = bool
  description = "- (Required) Whether to create subnetworks automatically."
}

variable "subnet_us_name" {
    type        = string
    description = "- (Required) Name of the subnet in us-a."
}

variable "subnet_us_range" {
    type        = string
    description = "- (Required) The range of internal addresses that are owned by this subnetwork."
}

#variable "cluster_version" {
#  type        = string
#  description = "- (Required) Version of the cluster."
#}

variable "master_ipv4_cidr_block" {
#  type        = string
  description = "IP range for the control plane"
#  default     = "172.16.0.16/28"
}
variable "cluster_network" {
  type        = string
  default     = "default"
  description = "- (Optional) The name or self_link of the Google Compute Engine network to which the cluster is connected. For Shared VPC, set this to the self link of the shared network."
}

#variable "node_pool_service_account" {
#  type        = string
#  description = "Service account to be associated with NodePools"
#}

variable "cluster_name" {
  type        = string
  description = "- (Required) The name of the cluster, unique within the project and location."
}

variable "subnetwork" {
  type        = string
  default     = "default"
  description = "- (Optional) The name or self_link of the Google Compute Engine subnetwork in which the cluster's instances are launched."
}

variable "node_version" {
  description = "- (Optional) The name of the GKE cluster to bind this node pool."
  default     = "1.17"
}

variable "min_master_version" {
  description = "- (Optional) The kubernetes version for the nodes in the pool. This should match the Kubernetes version of the GKE cluster."
  default     = "1.17"
}

variable "gce_ssh_pub_key_file" {
  description = "- (Optional) ssh pub key file"
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_nodes" {
  type    = bool
}

variable "enable_private_endpoint" {
  type = bool
}

variable "node_pools" {
  type = list(object({
    name               = string
    initial_node_count = number
    auto_repair = bool
    auto_upgrade = bool
    min_node_count = number
    max_node_count = number
    image_type   = string
    disk_size_gb = string
    preemptible  = bool
    machine_type = string
    labels = map(any)
    #      service_account = string
    metadata = object({ disable-legacy-endpoints = string })
    }))
}

variable "zone" {
    type        = string
    description = "- (Required) Google zone where the cluster will be deployed."
}

variable "cluster_location" {
    type        = string
    description = "- (Required) Zone (zonal cluster, cheap) or region (regional cluster, node counts multiply per zone) for the GKE cluster."
}

variable "enable_nat" {
    type        = bool
    default     = false
    description = "- (Optional) Create Cloud Router + Cloud NAT. Must be true whenever private_nodes is true, or node image pulls from Docker Hub will fail."
}

variable "ssh_source_ranges" {
    type        = list(string)
    default     = ["0.0.0.0/0"]
    description = "- (Optional) Source CIDRs allowed to reach port 22. Narrow to your own IP/32 for anything long-lived."
}

variable "ssh_firewall_rule_name" {
    type        = string
    description = "- (Required) Name of the firewall rule to allow SSH access to the cluster."
}

variable "control_network" {
    type        = string
    description = "- (Required) Name of the control network where the cluster will be deployed."
}

variable "instance_name" {
    type        = string
    description = "Name of the instance"
}

variable "instance_type" {
    type        = string
    description = "Type of the instance"
}

variable "instance_image" {
    type        = string
    description = "Image of the instance"
}
