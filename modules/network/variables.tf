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

variable "ssh_firewall_rule_name" {
  type        = string
  description = "- (Required) Name of the firewall rule to allow SSH access to the cluster."
}

variable "ssh_source_ranges" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "- (Optional) Who may reach port 22. Defaults to the whole internet; narrow this to your own IP/32 for anything long-lived."
}

variable "egress_firewall_rule_name" {
  type        = string
  default     = "egress-firewall-rule"
  description = "- (Optional) Name of the firewall rule to allow egress traffic to the internet."
}

variable "allow_ingress_firewall_rule_name" {
  type        = string
  default     = "ingress-firewall-rule"
  description = "- (Optional) Name of the firewall rule to allow HTTP ingress."
}

variable "enable_nat" {
  type        = bool
  default     = false
  description = "- (Optional) Create a Cloud Router + Cloud NAT so instances without public IPs can reach the internet. Required when private_nodes = true."
}
