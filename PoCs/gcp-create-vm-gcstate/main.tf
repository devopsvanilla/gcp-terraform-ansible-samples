data "google_project" "current" {
  project_id = var.project_id
}

locals {
  effective_form_vm_name = coalesce(
    trimspace(var.name) != "" ? var.name : null,
    trimspace(var.vm_name) != "" ? var.vm_name : null,
    "vm-nginx-poc"
  )

  form_vm_config = {
    for k in [local.effective_form_vm_name] : k => {
      vm_name                          = local.effective_form_vm_name
      machine_type_override            = var.machine_type_override
      machine_series                   = var.machine_series
      vcpu_count                       = var.vcpu_count
      memory_gb                        = var.memory_gb
      memory_mb                        = var.memory_gb * 1024
      machine_type                     = trimspace(var.machine_type_override) != "" ? var.machine_type_override : format("%s-custom-%d-%d", var.machine_series, var.vcpu_count, var.memory_gb * 1024)
      disk_type                        = var.disk_type
      disk_size_gb                     = var.disk_size_gb
      boot_image_project               = var.boot_image_project
      boot_image_family                = var.boot_image_family
      assign_external_ip               = var.assign_external_ip
      ssh_username                     = var.ssh_username
      ssh_public_key                   = var.ssh_public_key
      user_groups                      = var.user_groups
      network_name                     = var.network_name
      subnetwork_name                  = var.subnetwork_name
      allowed_http_cidr                = var.allowed_http_cidr
      allowed_ssh_cidr                 = var.allowed_ssh_cidr
      manage_vm_external_ip_org_policy = var.manage_vm_external_ip_org_policy
    }
  }

  map_vm_configs = {
    for vm_key, vm in var.vms : vm_key => {
      vm_name                          = vm.vm_name
      machine_type_override            = vm.machine_type_override
      machine_series                   = vm.machine_series
      vcpu_count                       = vm.vcpu_count
      memory_gb                        = vm.memory_gb
      memory_mb                        = vm.memory_gb * 1024
      machine_type                     = trimspace(vm.machine_type_override) != "" ? vm.machine_type_override : format("%s-custom-%d-%d", vm.machine_series, vm.vcpu_count, vm.memory_gb * 1024)
      disk_type                        = vm.disk_type
      disk_size_gb                     = vm.disk_size_gb
      boot_image_project               = vm.boot_image_project
      boot_image_family                = vm.boot_image_family
      assign_external_ip               = vm.assign_external_ip
      ssh_username                     = try(trimspace(vm.ssh_username), "") != "" ? vm.ssh_username : var.ssh_username
      ssh_public_key                   = try(trimspace(vm.ssh_public_key), "") != "" ? vm.ssh_public_key : var.ssh_public_key
      user_groups                      = compact([for g in(can(tolist(vm.user_groups)) ? tolist(vm.user_groups) : split(",", replace(replace(tostring(vm.user_groups), "[", ""), "]", ""))) : trimspace(g)])
      network_name                     = try(trimspace(vm.network_name), "") != "" ? vm.network_name : var.network_name
      subnetwork_name                  = try(trimspace(vm.subnetwork_name), "") != "" ? vm.subnetwork_name : var.subnetwork_name
      allowed_http_cidr                = try(trimspace(vm.allowed_http_cidr), "") != "" ? vm.allowed_http_cidr : var.allowed_http_cidr
      allowed_ssh_cidr                 = try(trimspace(vm.allowed_ssh_cidr), "") != "" ? vm.allowed_ssh_cidr : var.allowed_ssh_cidr
      manage_vm_external_ip_org_policy = coalesce(try(vm.manage_vm_external_ip_org_policy, null), var.manage_vm_external_ip_org_policy)
    }
  }

  vm_configs = trimspace(var.name) != "" || trimspace(var.vm_name) != "" ? local.form_vm_config : local.map_vm_configs

  vm_external_ip_allowed_values = distinct(flatten([
    for k, vm in local.vm_configs : (vm.assign_external_ip && vm.manage_vm_external_ip_org_policy ? [
      "projects/${var.project_id}/zones/${var.zone}/instances/${vm.vm_name}",
      "projects/${data.google_project.current.number}/zones/${var.zone}/instances/${vm.vm_name}",
    ] : [])
  ]))

  manage_vm_external_ip_org_policy_effective = var.manage_vm_external_ip_org_policy && length(local.vm_external_ip_allowed_values) > 0

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

resource "google_project_service" "org_policy" {
  count              = local.manage_vm_external_ip_org_policy_effective ? 1 : 0
  project            = var.project_id
  service            = "orgpolicy.googleapis.com"
  disable_on_destroy = false
}

resource "null_resource" "set_quota_project" {
  count = local.manage_vm_external_ip_org_policy_effective && length(local.vm_external_ip_allowed_values) > 0 ? 1 : 0

  triggers = {
    project_id = var.project_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -eu
      if command -v gcloud >/dev/null 2>&1; then
        gcloud auth application-default set-quota-project "${var.project_id}" || true
      else
        echo "gcloud CLI não encontrado no PATH do runner; ignorando set-quota-project."
      fi
    EOT
  }
}

resource "google_org_policy_policy" "vm_external_ip_access" {
  count  = local.manage_vm_external_ip_org_policy_effective ? 1 : 0
  name   = "projects/${var.project_id}/policies/compute.vmExternalIpAccess"
  parent = "projects/${var.project_id}"

  lifecycle {
    precondition {
      condition     = var.manage_vm_external_ip_org_policy ? true : true
      error_message = "Se manage_vm_external_ip_org_policy = true, a conta usada pelo Terraform precisa ter permissão para alterar a Org Policy compute.vmExternalIpAccess no projeto e a API orgpolicy.googleapis.com precisa estar habilitada."
    }
  }

  depends_on = [google_project_service.org_policy, null_resource.set_quota_project]

  spec {
    rules {
      values {
        allowed_values = local.vm_external_ip_allowed_values
      }
    }
  }
}

resource "google_compute_instance" "vm" {
  for_each = local.vm_configs

  name         = each.value.vm_name
  machine_type = each.value.machine_type
  zone         = var.zone

  depends_on = [
    google_project_service.compute_engine,
    google_org_policy_policy.vm_external_ip_access,
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

