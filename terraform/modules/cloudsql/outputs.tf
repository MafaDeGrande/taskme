output "instance_name" {
  description = "The name of the Cloud SQL instance"
  value       = module.postgresql.instance_name
}

output "instance_ip" {
  description = "The private IP address of the Cloud SQL instance"
  value       = module.postgresql.private_ip_address
}

output "instance_connection_name" {
  description = "The connection name of the Cloud SQL instance"
  value       = module.postgresql.instance_connection_name
}

output "credentials_secret_id" {
  description = "Secret Manager secret ID containing database credentials"
  value       = google_secret_manager_secret.db_credentials.id
}
