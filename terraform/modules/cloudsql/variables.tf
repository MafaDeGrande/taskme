variable "name" {
  description = "Base name for resources"
  type        = string
}

variable "project_id" {
  description = "The Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "The Google Cloud region"
  type        = string
}

variable "private_network" {
  description = "The VPC network self link"
  type        = string
}

variable "allocated_ip_range" {
  description = "private service access range name for Cloud SQL"
  type        = string
}

variable "disk_size" {
  type    = number
  default = 500
}
