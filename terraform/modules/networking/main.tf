# VPC Network
module "network" {
  source  = "terraform-google-modules/network/google"
  version = "~> 18.2"

  project_id              = var.project_id
  network_name            = "${var.name}-vpc"
  routing_mode            = "REGIONAL"
  auto_create_subnetworks = false

  subnets = [
    {
      subnet_name           = "${var.name}-gke-subnet"
      subnet_ip             = var.gke_nodes_cidr
      subnet_region         = var.region
      subnet_private_access = "true"
      subnet_flow_logs      = "true"
    }
  ]

  secondary_ranges = {
    "${var.name}-gke-subnet" = [
      {
        range_name    = "${var.name}-pods"
        ip_cidr_range = var.gke_pods_cidr
      },
      {
        range_name    = "${var.name}-services"
        ip_cidr_range = var.gke_services_cidr
      }
    ]
  }
}

# Cloud NAT for private nodes
resource "google_compute_router" "this" {
  name    = "${var.name}-router"
  region  = var.region
  network = module.network.network_id
  project = var.project_id
}

resource "google_compute_router_nat" "this" {
  name                               = "${var.name}-nat"
  router                             = google_compute_router.this.name
  region                             = var.region
  project                            = var.project_id
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = module.network.subnets["${var.region}/${var.name}-gke-subnet"].self_link
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# Private IP range for Cloud SQL
resource "google_compute_global_address" "private_ip_range" {
  name          = "${var.name}-cloudsql-psa"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  address       = cidrhost(var.cloudsql_psa_cidr, 0)
  prefix_length = tonumber(split("/", var.cloudsql_psa_cidr)[1])
  network       = module.network.network_id
  project       = var.project_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = module.network.network_id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
}
