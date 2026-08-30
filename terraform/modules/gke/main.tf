module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version = "~> 44.3"

  project_id = var.project_id
  name       = "${var.name}-cluster"
  region     = var.region
  zones      = ["${var.region}-a", "${var.region}-b", "${var.region}-c"]

  network           = var.vpc_name
  subnetwork        = var.subnetwork
  ip_range_pods     = var.secondary_range_pods
  ip_range_services = var.secondary_range_services

  # Private cluster configuration
  enable_private_endpoint = true
  enable_private_nodes    = true
  master_ipv4_cidr_block  = "172.16.0.0/28"

  horizontal_pod_autoscaling = true
  network_policy             = true
  http_load_balancing        = true
  filestore_csi_driver       = false
  dns_cache                  = false

  # Monitoring and logging
  monitoring_enable_managed_prometheus = true

  # Binary authorization
  enable_binary_authorization = true

  # Shielded nodes
  enable_shielded_nodes = true

  enable_vertical_pod_autoscaling = terraform.workspace == "production" ? true : false

  # Workload Identity
  identity_namespace = "${var.project_id}.svc.id.goog"

  # Maintenance window
  maintenance_start_time = "03:00"

  # Node pools
  node_pools = [
    {
      name               = "system-pool"
      machine_type       = "e2-standard-4"
      node_locations     = terraform.workspace == "production" ? ("${var.region}-a,${var.region}-b,${var.region}-c") : "${var.region}-a"
      autoscaling        = true
      total_min_count    = 1
      total_max_count    = terraform.workspace == "production" ? 3 : 1
      initial_node_count = 1

      local_ssd_count        = 0
      spot                   = false
      disk_size_gb           = 50
      disk_type              = "pd-balanced"
      image_type             = "COS_CONTAINERD"
      enable_gcfs            = false
      enable_gvnic           = false
      auto_repair            = true
      auto_upgrade           = true
      create_service_account = true
      preemptible            = false
    },
    {
      name         = "application-pool"
      machine_type = terraform.workspace == "production" ? "e2-standard-4" : "e2-standard-2"
      node_locations = terraform.workspace == "production" ? (
        "${var.region}-a,${var.region}-b,${var.region}-c"
      ) : "${var.region}-a"
      autoscaling        = true
      total_min_count    = terraform.workspace == "production" ? 3 : 1
      total_max_count    = terraform.workspace == "production" ? 10 : 2
      initial_node_count = 1

      local_ssd_count        = 0
      spot                   = false
      disk_size_gb           = 50
      disk_type              = "pd-balanced"
      image_type             = "COS_CONTAINERD"
      enable_gcfs            = false
      enable_gvnic           = false
      auto_repair            = true
      auto_upgrade           = true
      create_service_account = true
      preemptible            = false
    }
  ]

  # Node pool labels
  node_pools_labels = {
    system-pool = {
      environment = terraform.workspace
      cluster     = var.name
      workload    = "system"
    }
    application-pool = {
      environment = terraform.workspace
      cluster     = var.name
      workload    = "application"
    }
  }

  # Node pool metadata
  node_pools_metadata = {
    system-pool = {
      disable-legacy-endpoints = "true"
    }
    application-pool = {
      disable-legacy-endpoints = "true"
    }
  }

  # Node pool tags
  node_pools_tags = {
    system-pool = [
      "gke-node",
      "${var.name}-gke-system-node"
    ]
    application-pool = [
      "gke-node",
      "${var.name}-gke-application-node"
    ]
  }

  # Node pool OAuth scopes
  node_pools_oauth_scopes = {
    system-pool = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
    application-pool = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
