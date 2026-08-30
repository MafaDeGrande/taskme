output "network_name" {
  description = "Name of the custom VPC network"
  value       = module.network.network_name
}

output "network_id" {
  description = "ID of the custom VPC network"
  value       = module.network.network_id
}

output "network_self_link" {
  description = "Self-link of the custom VPC network"
  value       = module.network.network_self_link
}

output "gke_subnet_name" {
  description = "Name of the subnet used by GKE nodes"
  value       = module.network.subnets["${var.region}/${var.name}-gke-subnet"].name
}

output "gke_subnet_id" {
  description = "ID of the subnet used by GKE nodes"
  value       = module.network.subnets["${var.region}/${var.name}-gke-subnet"].id
}

output "gke_subnet_self_link" {
  description = "Self-link of the subnet used by GKE nodes"
  value       = module.network.subnets["${var.region}/${var.name}-gke-subnet"].self_link
}

output "gke_nodes_cidr" {
  description = "Primary IPv4 CIDR used by GKE nodes"
  value       = var.gke_nodes_cidr
}

output "gke_pods_range_name" {
  description = "Name of the GKE pods secondary range"
  value       = "${var.name}-pods"
}

output "gke_pods_cidr" {
  description = "IPv4 CIDR used by GKE pods"
  value       = var.gke_pods_cidr
}

output "gke_services_range_name" {
  description = "Name of the GKE services secondary range"
  value       = "${var.name}-services"
}

output "gke_services_cidr" {
  description = "IPv4 CIDR used by GKE services"
  value       = var.gke_services_cidr
}

output "cloudsql_psa_range_name" {
  description = "Name of the allocated Private Service Access range for Cloud SQL"
  value       = google_compute_global_address.private_ip_range.name
}

output "cloudsql_psa_cidr" {
  description = "IPv4 CIDR allocated to Cloud SQL Private Service Access"
  value       = var.cloudsql_psa_cidr
}

output "router_name" {
  description = "Name of the Cloud Router used by Cloud NAT"
  value       = google_compute_router.this.name
}

output "nat_name" {
  description = "Name of the Cloud NAT gateway"
  value       = google_compute_router_nat.this.name
}
