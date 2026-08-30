output "project_id" {
  description = "Google Cloud project ID"
  value       = local.project_id
}

output "environment" {
  description = "deployment environment"
  value       = terraform.workspace
}

output "region" {
  description = "Google Cloud region"
  value       = var.region
}

output "gke_cluster_name" {
  description = "GKE cluster name"
  value       = module.gke.cluster_name
}

output "gke_cluster_location" {
  description = "GKE cluster location"
  value       = module.gke.location
}

output "database_connection_name" {
  description = "Cloud SQL connection name"
  value       = module.database.instance_connection_name
}

output "database_credentials_secret_id" {
  description = "Secret Manager secret ID containing database credentials"
  value       = module.database.credentials_secret_id
}
