# Copyright 2025-2026 Hewlett Packard Enterprise Development LP
provider "hpe" {
  morpheus {
    url              = var.morpheus_url
    username         = var.morpheus_username != "" ? var.morpheus_username : null
    password         = var.morpheus_password != "" ? var.morpheus_password : null
    access_token     = var.morpheus_access_token != "" ? var.morpheus_access_token : null
    tenant_subdomain = var.morpheus_tenant_subdomain != "" ? var.morpheus_tenant_subdomain : null
    insecure         = var.morpheus_insecure
  }
}
