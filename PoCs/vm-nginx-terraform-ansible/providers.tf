locals {
  raw_gcp_credentials = try(trimspace(var.gcp_credentials), "")
  gcp_credentials_json = (
    local.raw_gcp_credentials == ""
    ? null
    : can(jsondecode(local.raw_gcp_credentials))
    ? local.raw_gcp_credentials
    : can(base64decode(local.raw_gcp_credentials))
    ? base64decode(local.raw_gcp_credentials)
    : local.raw_gcp_credentials
  )
}

provider "google" {
  project               = var.project_id
  region                = var.region
  zone                  = var.zone
  billing_project       = var.project_id
  user_project_override = true
  credentials           = local.gcp_credentials_json
}

