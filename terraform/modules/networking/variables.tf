variable "project_id" {
  type        = string
  description = "project id"
}

variable "name" {
  type        = string
  description = "name of created resources"
}

variable "region" {
  description = "the Google Cloud region"
  type        = string
}

variable "gke_nodes_cidr" {
  description = "primary ipv4 cirdr for GKE nodes"
  type        = string
  default     = "10.0.0.0/24"
}

variable "gke_pods_cidr" {
  description = "secondary ipv4 cidr for GKE pods"
  type        = string
  default     = "10.1.0.0/16"
}

variable "gke_services_cidr" {
  description = "secondary ipv4 cidr for GKE services"
  type        = string
  default     = "10.2.0.0/16"
}

variable "cloudsql_psa_cidr" {
  description = "ipv4 cidr reserved for Cloud SQL Private Service Access"
  type        = string
  default     = "10.3.0.0/16"
}
