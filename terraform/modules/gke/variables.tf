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

variable "vpc_name" {
  description = "The VPC network name"
  type        = string
}

variable "subnetwork" {
  description = "The VPC subnetwork name"
  type        = string
}

variable "secondary_range_pods" {
  description = "The secondary range name for pods"
  type        = string
}

variable "secondary_range_services" {
  description = "The secondary range name for services"
  type        = string
}
