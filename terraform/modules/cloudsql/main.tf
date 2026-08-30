# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

locals {
  db_name   = "${replace(var.name, "-", "_")}_db"
  user_name = "${replace(var.name, "-", "_")}_user"
  ip_configuration = {
    ipv4_enabled                                  = false
    ssl_mode                                      = "ALLOW_UNENCRYPTED_AND_ENCRYPTED"
    private_network                               = var.private_network
    enable_private_path_for_google_cloud_services = true
    authorized_networks                           = []
    allocated_ip_range                            = var.allocated_ip_range
  }
}

module "postgresql" {
  source  = "terraform-google-modules/sql-db/google//modules/postgresql"
  version = "~> 28.1"

  name                        = "${var.name}-postgres"
  project_id                  = var.project_id
  database_version            = "POSTGRES_15"
  region                      = var.region
  zone                        = "${var.region}-a"
  secondary_zone              = "${var.region}-b"
  availability_type           = "REGIONAL"
  tier                        = terraform.workspace == "production" ? "db-custom-8-16384" : "db-custom-4-8192"
  deletion_protection         = true
  deletion_protection_enabled = true

  # Disk configuration
  disk_type       = "PD_SSD"
  disk_size       = terraform.workspace == "production" ? var.disk_size : 20
  disk_autoresize = true

  # Network configuration
  ip_configuration = local.ip_configuration
  # Backup configuration
  backup_configuration = {
    enabled                        = true
    start_time                     = "16:00"
    location                       = null
    point_in_time_recovery_enabled = true
    transaction_log_retention_days = 7
    retained_backups               = 7
    retention_unit                 = "COUNT"
  }
  # Maintenance window
  maintenance_window_day          = 7 # Sunday
  maintenance_window_hour         = 17
  maintenance_window_update_track = "stable"

  # Database flags
  database_flags = [
    {
      name  = "log_checkpoints"
      value = "on"
    },
    {
      name  = "log_connections"
      value = "on"
    },
    {
      name  = "log_disconnections"
      value = "on"
    },
    {
      name  = "log_lock_waits"
      value = "on"
    }
  ]

  # Insights configuration
  insights_config = {
    query_plans_per_minute  = 5
    query_string_length     = 1024
    record_application_tags = false
    record_client_address   = false
  }

  # Database and user configuration
  db_name      = local.db_name
  db_charset   = "UTF8"
  db_collation = "en_US.UTF8"

  user_name     = local.user_name
  user_password = random_password.db_password.result

  user_labels = { environment = terraform.workspace }
}

resource "google_sql_database" "database" {
  count    = contains(["staging", "dev"], terraform.workspace) ? 1 : 0
  name     = "${local.db_name}-identity"
  instance = module.postgresql.instance_name
}

# Store database credentials in Secret Manager
resource "google_secret_manager_secret" "db_credentials" {
  secret_id = "${var.name}-db-credentials"
  project   = var.project_id

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_credentials" {
  secret = google_secret_manager_secret.db_credentials.id
  secret_data = jsonencode({
    password          = random_password.db_password.result
    user_name         = local.user_name
    db_name           = local.db_name
    host              = module.postgresql.private_ip_address
    port              = "5432"
    connection_string = "postgresql://${local.user_name}:${random_password.db_password.result}@${module.postgresql.private_ip_address}:5432/${local.db_name}"
  })
}
