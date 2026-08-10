provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = try(trimspace(var.gcp_credentials), "") != "" ? (can(base64decode(var.gcp_credentials)) && !can(jsondecode(var.gcp_credentials)) ? base64decode(var.gcp_credentials) : var.gcp_credentials) : null
}
