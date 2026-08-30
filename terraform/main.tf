locals {
  prefix     = "medi"
  env        = terraform.workspace
  name       = "${local.prefix}-${local.env}"
  project_id = "medi"
}

module "vpc" {
  source     = "./modules/networking"
  name       = local.name
  project_id = local.project_id
  region     = var.region
}

module "gke" {
  source     = "./modules/gke"
  name       = local.name
  project_id = local.project_id
  region     = var.region
  vpc_name   = module.vpc.network_name
  subnetwork = module.vpc.gke_subnet_name

  secondary_range_pods     = module.vpc.gke_pods_range_name
  secondary_range_services = module.vpc.gke_services_range_name
  depends_on               = [module.vpc]
}

module "database" {
  source             = "./modules/cloudsql"
  name               = local.name
  project_id         = local.project_id
  region             = var.region
  private_network    = module.vpc.network_self_link
  allocated_ip_range = module.vpc.cloudsql_psa_range_name
  depends_on         = [module.vpc]
}
