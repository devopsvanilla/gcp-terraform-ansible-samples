provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = var.gcp_credentials != "" ? (can(base64decode(var.gcp_credentials)) ? base64decode(var.gcp_credentials) : var.gcp_credentials) : null
}
