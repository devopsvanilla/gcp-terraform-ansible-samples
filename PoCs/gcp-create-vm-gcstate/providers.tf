provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = fileexists("/var/opt/morpheus/gcp-key.json") ? file("/var/opt/morpheus/gcp-key.json") : (var.gcp_credentials != "" && var.gcp_credentials != null ? try(base64decode(var.gcp_credentials), var.gcp_credentials) : null)
}
