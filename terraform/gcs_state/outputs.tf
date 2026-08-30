output "state_bucket_name" {
  description = "GCS bucket name used by the Terraform backend"
  value       = google_storage_bucket.this.name
}

output "state_prefix" {
  description = "GCS object prefix used by the Terraform backend"
  value       = "tfstate"
}
