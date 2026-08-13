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

variable "network_name" {
    type        = string
    description = "Name of the network"
}

variable "zone" {
    type        = string
    description = "Zone of the instance"
}

variable "subnetwork_name" {
    type        = string
    description = "Name of the subnetwork"
}