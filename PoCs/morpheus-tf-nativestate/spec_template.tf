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
  credentials = jsonencode(jsondecode(var.gcp_credentials))
}

locals {
  vm_name               = "<%= (customOptions.name != null && customOptions.name != '') ? customOptions.name : ((customOptions.vm_name != null && customOptions.vm_name != '') ? customOptions.vm_name : 'vm-gcp-poc') %>"
  machine_series        = "<%= (customOptions.machine_series != null && customOptions.machine_series != '') ? customOptions.machine_series : 'e2' %>"
  machine_type_override = "<%= (customOptions.machine_type_override != null && customOptions.machine_type_override != '') ? customOptions.machine_type_override : 'e2-micro' %>"
  vcpu_count            = <%= (customOptions.vcpu_count != null && customOptions.vcpu_count != '') ? customOptions.vcpu_count : 1 %>
  memory_gb             = <%= (customOptions.memory_gb != null && customOptions.memory_gb != '') ? customOptions.memory_gb : 1 %>
  disk_type             = "<%= (customOptions.disk_type != null && customOptions.disk_type != '') ? customOptions.disk_type : 'pd-standard' %>"
  disk_size_gb          = <%= (customOptions.disk_size_gb != null && customOptions.disk_size_gb != '') ? customOptions.disk_size_gb : 30 %>
  boot_image_project    = "<%= (customOptions.boot_image_project != null && customOptions.boot_image_project != '') ? customOptions.boot_image_project : 'debian-cloud' %>"
  boot_image_family     = "<%= (customOptions.boot_image_family != null && customOptions.boot_image_family != '') ? customOptions.boot_image_family : 'debian-12' %>"
  assign_external_ip    = <%= (customOptions.assign_external_ip != null && customOptions.assign_external_ip != '') ? customOptions.assign_external_ip : true %>
  ssh_username          = "<%= (customOptions.ssh_username != null && customOptions.ssh_username != '') ? customOptions.ssh_username : 'devopsvanilla' %>"
  ssh_public_key        = "<%= (customOptions.ssh_public_key != null && customOptions.ssh_public_key != '') ? customOptions.ssh_public_key : '' %>"
  network_name          = "<%= (customOptions.network_name != null && customOptions.network_name != '') ? customOptions.network_name : 'default' %>"
  subnetwork_name       = "<%= (customOptions.subnetwork_name != null && customOptions.subnetwork_name != '') ? customOptions.subnetwork_name : '' %>"
  allowed_http_cidr     = "<%= (customOptions.allowed_http_cidr != null && customOptions.allowed_http_cidr != '') ? customOptions.allowed_http_cidr : '0.0.0.0/0' %>"
  allowed_ssh_cidr      = "<%= (customOptions.allowed_ssh_cidr != null && customOptions.allowed_ssh_cidr != '') ? customOptions.allowed_ssh_cidr : '0.0.0.0/0' %>"

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
      size  = local.disk_size_gb
    }
  }

  network_interface {
    network    = local.network_name
    subnetwork = local.subnetwork_name != "" ? local.subnetwork_name : null

    dynamic "access_config" {
      for_each = local.assign_external_ip ? [1] : []
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
