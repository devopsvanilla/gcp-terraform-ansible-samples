data "google_project" "current" {
  project_id = var.project_id
}

locals {
  raw_form_vm_name = coalesce(
    trimspace(var.vm_name) != "" ? var.vm_name : null,
    trimspace(var.name) != "" ? var.name : null,
    trimspace(var.app_name) != "" ? var.app_name : null,
    trimspace(var.morpheus_app_name) != "" ? var.morpheus_app_name : null,
    trimspace(var.morpheus_resource_name) != "" ? var.morpheus_resource_name : null,
    "vm-gcp-poc"
  )

  clean_name_chars       = lower(replace(replace(local.raw_form_vm_name, "/[^a-zA-Z0-9-]/", "-"), "/-+/", "-"))
  sanitized_form_vm_name = trim(local.clean_name_chars, "-")
  effective_form_vm_name = length(regexall("^[a-z]", local.sanitized_form_vm_name)) > 0 ? (
    length(local.sanitized_form_vm_name) > 0 ? local.sanitized_form_vm_name : "vm-gcp-poc"
  ) : "vm-${local.sanitized_form_vm_name}"

  form_vm_config = {
    for k in [local.effective_form_vm_name] : k => {
      vm_name               = local.effective_form_vm_name
      machine_type_override = var.machine_type_override
      machine_series        = var.machine_series
      vcpu_count            = try(tonumber(var.vcpu_count), 1)
      memory_gb             = try(tonumber(var.memory_gb), 1)
      memory_mb             = try(tonumber(var.memory_gb), 1) * 1024
      machine_type = (
        trimspace(var.machine_type_override) == "" ||
        trimspace(var.machine_type_override) == "custom" ||
        (var.machine_type_override == "e2-micro" && (try(tonumber(var.memory_gb), 1) > 1 || try(tonumber(var.vcpu_count), 1) > 1))
        ) ? format(
        "%s-custom-%d-%d",
        var.machine_series,
        (var.machine_series == "e2" ? max(try(tonumber(var.vcpu_count), 2), 2) : try(tonumber(var.vcpu_count), 1)),
        try(tonumber(var.memory_gb), 1) * 1024
      ) : var.machine_type_override
      disk_type          = var.disk_type
      disk_size_gb       = try(tonumber(var.disk_size_gb), 30)
      boot_image_project = var.boot_image_project
      boot_image_family  = var.boot_image_family
      assign_external_ip = can(tobool(var.assign_external_ip)) ? tobool(var.assign_external_ip) : (lower(tostring(var.assign_external_ip)) == "true" || lower(tostring(var.assign_external_ip)) == "on")
      ssh_username       = var.ssh_username
      ssh_public_key     = var.ssh_public_key
      user_groups        = compact([for g in(can(tolist(var.user_groups)) ? tolist(var.user_groups) : split(",", replace(replace(tostring(var.user_groups), "[", ""), "]", ""))) : trimspace(g)])
      network_name       = var.network_name
      subnetwork_name    = var.subnetwork_name
      allowed_http_cidr  = can(cidrhost(var.allowed_http_cidr, 0)) ? var.allowed_http_cidr : "0.0.0.0/0"
      allowed_ssh_cidr   = can(cidrhost(var.allowed_ssh_cidr, 0)) ? var.allowed_ssh_cidr : "0.0.0.0/0"
    }
  }

  map_vm_configs = {
    for vm_key, vm in var.vms : vm_key => {
      vm_name               = vm.vm_name
      machine_type_override = vm.machine_type_override
      machine_series        = vm.machine_series
      vcpu_count            = vm.vcpu_count
      memory_gb             = vm.memory_gb
      memory_mb             = vm.memory_gb * 1024
      machine_type          = trimspace(vm.machine_type_override) != "" ? vm.machine_type_override : format("%s-custom-%d-%d", vm.machine_series, vm.vcpu_count, vm.memory_gb * 1024)
      disk_type             = vm.disk_type
      disk_size_gb          = vm.disk_size_gb
      boot_image_project    = vm.boot_image_project
      boot_image_family     = vm.boot_image_family
      assign_external_ip    = vm.assign_external_ip
      ssh_username          = try(trimspace(vm.ssh_username), "") != "" ? vm.ssh_username : var.ssh_username
      ssh_public_key        = try(trimspace(vm.ssh_public_key), "") != "" ? vm.ssh_public_key : var.ssh_public_key
      user_groups           = compact([for g in(can(tolist(vm.user_groups)) ? tolist(vm.user_groups) : split(",", replace(replace(tostring(vm.user_groups), "[", ""), "]", ""))) : trimspace(g)])
      network_name          = try(trimspace(vm.network_name), "") != "" ? vm.network_name : var.network_name
      subnetwork_name       = try(trimspace(vm.subnetwork_name), "") != "" ? vm.subnetwork_name : var.subnetwork_name
      allowed_http_cidr     = can(cidrhost(try(trimspace(vm.allowed_http_cidr), ""), 0)) ? vm.allowed_http_cidr : (can(cidrhost(var.allowed_http_cidr, 0)) ? var.allowed_http_cidr : "0.0.0.0/0")
      allowed_ssh_cidr      = can(cidrhost(try(trimspace(vm.allowed_ssh_cidr), ""), 0)) ? vm.allowed_ssh_cidr : (can(cidrhost(var.allowed_ssh_cidr, 0)) ? var.allowed_ssh_cidr : "0.0.0.0/0")
    }
  }

  use_form_input = trimspace(var.vm_name) != "" || trimspace(var.name) != "" || trimspace(var.app_name) != "" || length(var.vms) == 0
  vm_configs     = local.use_form_input ? local.form_vm_config : local.map_vm_configs

  vm_metadata_ssh_keys = {
    for vm_key, vm in local.vm_configs : vm_key => compact([
      trimspace(vm.ssh_public_key),
    ])
  }

  vm_metadata_ssh_key_entries = {
    for vm_key, vm in local.vm_configs : vm_key => compact([
      for key_value in local.vm_metadata_ssh_keys[vm_key] : (trimspace(key_value) != "" ? format("%s:%s", vm.ssh_username, key_value) : "")
    ])
  }
}

resource "google_project_service" "compute_engine" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_instance" "vm" {
  for_each = local.vm_configs

  name         = each.value.vm_name
  machine_type = each.value.machine_type
  zone         = var.zone

  depends_on = [
    google_project_service.compute_engine,
  ]

  tags = [
    "${var.poc_name}-${lower(replace(each.key, "_", "-"))}-http",
    "${var.poc_name}-${lower(replace(each.key, "_", "-"))}-ssh",
  ]

  boot_disk {
    initialize_params {
      image = "projects/${each.value.boot_image_project}/global/images/family/${each.value.boot_image_family}"
      type  = each.value.disk_type
      size  = each.value.disk_size_gb
    }
  }

  network_interface {
    network    = each.value.network_name
    subnetwork = each.value.subnetwork_name != "" ? each.value.subnetwork_name : null

    dynamic "access_config" {
      for_each = each.value.assign_external_ip ? [1] : []
      content {}
    }
  }

  metadata = var.use_metadata_ssh_keys ? {
    "ssh-keys" = join("\n", local.vm_metadata_ssh_key_entries[each.key])
  } : {}

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euo pipefail

    login_user="${each.value.ssh_username}"
    if [ -z "$login_user" ]; then
      exit 0
    fi

    if ! id -u "$login_user" >/dev/null 2>&1; then
      useradd -m -s /bin/bash "$login_user"
    fi

    %{for group in each.value.user_groups~}
    if ! getent group "${group}" >/dev/null 2>&1; then
      groupadd "${group}"
    fi
    usermod -aG "${group}" "$login_user" 2>/dev/null || true
    %{endfor~}

    usermod -aG sudo "$login_user" 2>/dev/null || true
    install -d -m 700 -o "$login_user" -g "$login_user" "/home/$login_user/.ssh"
    install -m 600 /dev/null "/home/$login_user/.ssh/authorized_keys"
    chown "$login_user:$login_user" "/home/$login_user/.ssh/authorized_keys"
    %{for key_value in local.vm_metadata_ssh_keys[each.key]~}
    printf '%s\n' "${key_value}" >> "/home/$login_user/.ssh/authorized_keys"
    %{endfor~}
    chmod 600 "/home/$login_user/.ssh/authorized_keys"
    chown -R "$login_user:$login_user" "/home/$login_user"

    if command -v sudo >/dev/null 2>&1; then
      install -d -m 750 /etc/sudoers.d
      echo "$login_user ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/99-$login_user-nopasswd"
      chmod 440 "/etc/sudoers.d/99-$login_user-nopasswd"
      if command -v visudo >/dev/null 2>&1; then
        visudo -cf "/etc/sudoers.d/99-$login_user-nopasswd"
      fi
    fi
  EOT
}

resource "google_compute_firewall" "allow_http" {
  for_each = local.vm_configs

  name    = "${var.poc_name}-${lower(replace(each.key, "_", "-"))}-allow-http"
  network = each.value.network_name

  depends_on = [google_project_service.compute_engine]

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [each.value.allowed_http_cidr]
  target_tags   = ["${var.poc_name}-${lower(replace(each.key, "_", "-"))}-http"]
}

resource "google_compute_firewall" "allow_ssh" {
  for_each = local.vm_configs

  name    = "${var.poc_name}-${lower(replace(each.key, "_", "-"))}-allow-ssh"
  network = each.value.network_name

  depends_on = [google_project_service.compute_engine]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [each.value.allowed_ssh_cidr]
  target_tags   = ["${var.poc_name}-${lower(replace(each.key, "_", "-"))}-ssh"]
}
