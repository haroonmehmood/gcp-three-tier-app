########################################
# CHANGE THIS BEFORE RUNNING TERRAFORM
########################################
project_id = "CHANGE-ME-your-gcp-project-id"

########################################
# Location
########################################
region = "us-central1"
zone   = "us-central1-a"

# A ZONE here means a zonal cluster and the node counts below are totals.
# Putting a REGION here would multiply every node count by the number of zones
# in that region (us-central1 has 4), which is what made the original config
# create 12 nodes and cost ~$900/month.
cluster_location = "us-central1-a"

########################################
# Network
########################################
vpc_name        = "three-tier-vpc"
auto_create_sub = false
subnet_us_name  = "us-a"
subnet_us_range = "10.0.0.0/24"

ssh_firewall_rule_name = "three-tier-allow-ssh"

# Open to the world so you can SSH from anywhere. Replace with ["<your-ip>/32"]
# for anything you intend to leave running.
ssh_source_ranges = ["0.0.0.0/0"]

########################################
# Cluster access + privacy
########################################
# Must stay in sync with CLOUDSDK_CONTAINER_CLUSTER in cloudbuild.yaml.
cluster_name = "three-tier-app"

control_network = "0.0.0.0/0"

# Nodes keep public IPs, so they can pull the WordPress and MySQL images
# straight from Docker Hub with no Cloud NAT needed. Cheapest working setup.
#
# To harden it later, set BOTH of these together:
#   private_nodes = true
#   enable_nat    = true
# Turning on private_nodes without enable_nat leaves the nodes with no route to
# Docker Hub and the WordPress/MySQL pods will hang in ImagePullBackOff.
private_nodes           = false
enable_nat              = false
enable_private_endpoint = false

# Must be a private RFC1918 /28. Only used when private_nodes = true, but it
# still has to be valid. The original value here was a public range and GKE
# rejected it outright.
master_ipv4_cidr_block = "172.16.0.0/28"

########################################
# Node pool
########################################
node_pools = [
  {
    name               = "pool"
    initial_node_count = 2
    auto_repair        = true
    auto_upgrade       = true
    min_node_count     = 2
    max_node_count     = 3
    image_type         = "cos_containerd"
    disk_size_gb       = "20"
    preemptible        = false
    machine_type       = "e2-medium"
    labels             = {}
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
]

########################################
# Standalone Apache VM
########################################
instance_name = "apache2"
instance_type = "e2-micro"

# Image family rather than a pinned build, so this keeps resolving as Google
# publishes new images. The old value (ubuntu-1804-bionic-v20220901) is EOL and
# has been deleted from Google's public catalog.
instance_image = "ubuntu-os-cloud/ubuntu-2204-lts"
