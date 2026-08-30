output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke.name
}

output "cluster_id" {
  description = "The ID of the GKE cluster"
  value       = module.gke.cluster_id
}

output "endpoint" {
  description = "The cluster endpoint"
  value       = module.gke.endpoint
  sensitive   = true
}

output "ca_certificate" {
  description = "The cluster CA certificate"
  value       = module.gke.ca_certificate
  sensitive   = true
}

output "service_account_email" {
  description = "The email of the GKE service account"
  value       = module.gke.service_account
}

output "location" {
  description = "The location of the GKE cluster"
  value       = module.gke.location
}
