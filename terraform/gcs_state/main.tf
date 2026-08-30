terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.46"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.6"
    }
  }
}

locals {
  region     = "us-central1"
  project_id = "medi"
}

resource "google_storage_bucket" "this" {
  name     = "${local.project_id}-terraform-state"
  location = local.region
  project  = local.project_id

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
    "secretmanager.googleapis.com",
    "binaryauthorization.googleapis.com"
  ])

  project                    = local.project_id
  service                    = each.key
  disable_dependent_services = true
}

# Generate backend configuration file
resource "local_file" "this" {
  content  = <<-EOF
    bucket  = "${google_storage_bucket.this.name}"
    prefix  = "tfstate"
  EOF
  filename = "../${path.root}/config/backend.hcl"
}
