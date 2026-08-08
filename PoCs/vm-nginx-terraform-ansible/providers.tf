provider "google" {
  project               = var.project_id
  region                = var.region
  zone                  = var.zone
  billing_project       = var.project_id
  user_project_override = true
  credentials           = var.gcp_credentials != "" ? var.gcp_credentials : null
}
