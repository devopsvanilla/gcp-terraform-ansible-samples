# Spec Template Terraform do Morpheus contendo o manifesto HCL completo.
# O Morpheus renderiza as variáveis dinâmicas (<%= customOptions... %>) no momento do provisionamento do App.
resource "hpe_morpheus_spec_template_terraform" "gcp_vm" {
  name         = "${var.blueprint_name}-hcl"
  source_type  = "local"
  spec_content = <<-EOT
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0, < 7.0.0"
    }
  }
}

variable "project_id" {
  type    = string
  default = "${var.project_id}"
}

variable "region" {
  type    = string
  default = "${var.region}"
}

variable "zone" {
  type    = string
  default = "${var.zone}"
}

provider "google" {
  project     = "${var.project_id}"
  region      = "${var.region}"
  zone        = "${var.zone}"
  credentials = ${jsonencode(var.gcp_credentials)}
}

variable "vm_name" {
  type    = string
  default = "<%=customOptions.vm_name%>"
}

variable "machine_series" {
  type    = string
  default = "<%=customOptions.machine_series%>"
}

variable "machine_type_override" {
  type    = string
  default = "<%=customOptions.machine_type_override%>"
}

variable "vcpu_count" {
  type    = any
  default = "<%=customOptions.vcpu_count%>"
}

variable "memory_gb" {
  type    = any
  default = "<%=customOptions.memory_gb%>"
}

variable "disk_type" {
  type    = string
  default = "<%=customOptions.disk_type%>"
}

variable "disk_size_gb" {
  type    = any
  default = "<%=customOptions.disk_size_gb%>"
}

variable "boot_image_project" {
  type    = string
  default = "<%=customOptions.boot_image_project%>"
}

variable "boot_image_family" {
  type    = string
  default = "<%=customOptions.boot_image_family%>"
}

variable "assign_external_ip" {
  type    = any
  default = "<%=customOptions.assign_external_ip%>"
}

variable "ssh_username" {
  type    = string
  default = "<%=customOptions.ssh_username%>"
}

variable "ssh_public_key" {
  type    = string
  default = "<%=customOptions.ssh_public_key%>"
}

variable "network_name" {
  type    = string
  default = "<%=customOptions.network_name%>"
}

variable "subnetwork_name" {
  type    = string
  default = "<%=customOptions.subnetwork_name%>"
}

variable "allowed_http_cidr" {
  type    = string
  default = "<%=customOptions.allowed_http_cidr%>"
}

variable "allowed_ssh_cidr" {
  type    = string
  default = "<%=customOptions.allowed_ssh_cidr%>"
}

locals {
  # Valores finais tratados com fallback seguro
  vm_name               = coalesce(trimspace(var.vm_name) != "" && var.vm_name != "null" && !can(regex("^<%", var.vm_name)) ? var.vm_name : null, "vm-gcp-poc")
  machine_series        = coalesce(trimspace(var.machine_series) != "" && var.machine_series != "null" && !can(regex("^<%", var.machine_series)) ? var.machine_series : null, "e2")
  machine_type_override = trimspace(var.machine_type_override) != "" && var.machine_type_override != "null" && !can(regex("^<%", var.machine_type_override)) ? var.machine_type_override : ""
  vcpu_count            = try(tonumber(var.vcpu_count), 1)
  memory_gb             = try(tonumber(var.memory_gb), 1)
  disk_type             = coalesce(trimspace(var.disk_type) != "" && var.disk_type != "null" && !can(regex("^<%", var.disk_type)) ? var.disk_type : null, "pd-standard")
  disk_size_gb          = try(tonumber(var.disk_size_gb), 30)
  boot_image_project    = coalesce(trimspace(var.boot_image_project) != "" && var.boot_image_project != "null" && !can(regex("^<%", var.boot_image_project)) ? var.boot_image_project : null, "debian-cloud")
  boot_image_family     = coalesce(trimspace(var.boot_image_family) != "" && var.boot_image_family != "null" && !can(regex("^<%", var.boot_image_family)) ? var.boot_image_family : null, "debian-12")
  assign_external_ip    = tostring(var.assign_external_ip) != "false" && tostring(var.assign_external_ip) != "off"
  ssh_username          = coalesce(trimspace(var.ssh_username) != "" && var.ssh_username != "null" && !can(regex("^<%", var.ssh_username)) ? var.ssh_username : null, "devopsvanilla")
  ssh_public_key        = trimspace(var.ssh_public_key) != "" && var.ssh_public_key != "null" && !can(regex("^<%", var.ssh_public_key)) ? var.ssh_public_key : ""
  network_name          = coalesce(trimspace(var.network_name) != "" && var.network_name != "null" && !can(regex("^<%", var.network_name)) ? var.network_name : null, "default")
  subnetwork_name       = trimspace(var.subnetwork_name) != "" && var.subnetwork_name != "null" && !can(regex("^<%", var.subnetwork_name)) ? var.subnetwork_name : ""
  allowed_http_cidr     = can(cidrhost(var.allowed_http_cidr, 0)) ? var.allowed_http_cidr : "0.0.0.0/0"
  allowed_ssh_cidr      = can(cidrhost(var.allowed_ssh_cidr, 0)) ? var.allowed_ssh_cidr : "0.0.0.0/0"

  machine_type = (
    trimspace(local.machine_type_override) == "" ||
    trimspace(local.machine_type_override) == "custom" ||
    (local.machine_type_override == "e2-micro" && (local.memory_gb > 1 || local.vcpu_count > 1))
  ) ? format(
    "%s-custom-%d-%d",
    local.machine_series,
    (local.machine_series == "e2" ? max(local.vcpu_count, 2) : local.vcpu_count),
    local.memory_gb * 1024
  ) : local.machine_type_override
}

resource "google_compute_instance" "vm" {
  name         = local.vm_name
  machine_type = local.machine_type
  zone         = var.zone

  tags = [
    "$${local.vm_name}-http",
    "$${local.vm_name}-ssh"
  ]

  boot_disk {
    initialize_params {
      image = "projects/$${local.boot_image_project}/global/images/family/$${local.boot_image_family}"
      type  = local.disk_type
      size  = try(tonumber(local.disk_size_gb), 30)
    }
  }

  network_interface {
    network    = local.network_name
    subnetwork = local.subnetwork_name != "" ? local.subnetwork_name : null

    dynamic "access_config" {
      for_each = try(tobool(local.assign_external_ip), true) ? [1] : []
      content {}
    }
  }

  metadata = local.ssh_public_key != "" ? {
    "ssh-keys" = "$${local.ssh_username}:$${local.ssh_public_key}"
  } : {}

  metadata_startup_script = <<-SCRIPT
    #!/bin/bash
    set -euo pipefail
    login_user="$${local.ssh_username}"
    if [ -n "$login_user" ]; then
      id -u "$login_user" >/dev/null 2>&1 || useradd -m -s /bin/bash "$login_user"
      usermod -aG sudo "$login_user" 2>/dev/null || true
      if [ -n "$${local.ssh_public_key}" ]; then
        install -d -m 700 -o "$login_user" -g "$login_user" "/home/$login_user/.ssh"
        echo "$${local.ssh_public_key}" > "/home/$login_user/.ssh/authorized_keys"
        chmod 600 "/home/$login_user/.ssh/authorized_keys"
        chown -R "$login_user:$login_user" "/home/$login_user"
      fi
      if command -v sudo >/dev/null 2>&1; then
        echo "$login_user ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/99-$login_user-nopasswd"
        chmod 440 "/etc/sudoers.d/99-$login_user-nopasswd"
      fi
    fi
  SCRIPT
}

resource "google_compute_firewall" "allow_http" {
  name    = "$${local.vm_name}-allow-http"
  network = local.network_name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [local.allowed_http_cidr]
  target_tags   = ["$${local.vm_name}-http"]
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "$${local.vm_name}-allow-ssh"
  network = local.network_name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [local.allowed_ssh_cidr]
  target_tags   = ["$${local.vm_name}-ssh"]
}

output "instance_id" {
  value = google_compute_instance.vm.instance_id
}

output "instance_name" {
  value = google_compute_instance.vm.name
}

output "machine_type" {
  value = google_compute_instance.vm.machine_type
}

output "disk_size_gb" {
  value = local.disk_size_gb
}

output "internal_ip" {
  value = try(google_compute_instance.vm.network_interface[0].network_ip, null)
}

output "external_ip" {
  value = try(google_compute_instance.vm.network_interface[0].access_config[0].nat_ip, null)
}
EOT
}
