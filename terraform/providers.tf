terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.46"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.46"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }
  backend "gcs" {}
}

provider "google" {
  project               = local.project_id
  region                = var.region
  user_project_override = true
  billing_project       = local.project_id
}

provider "google-beta" {
  project               = local.project_id
  region                = var.region
  user_project_override = true
  billing_project       = local.project_id
}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

data "google_client_config" "default" {}
