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

  ansible_public_key_path    = pathexpand("${var.ansible_private_key_file}.pub")
  ansible_public_key_content = trimspace(fileexists(local.ansible_public_key_path) ? file(local.ansible_public_key_path) : "")
  vm_metadata_ssh_keys = {
    for vm_key, vm in local.vm_configs : vm_key => compact([
      trimspace(vm.ssh_public_key),
      var.run_ansible && trimspace(local.ansible_public_key_content) != "" ? trimspace(local.ansible_public_key_content) : "",
    ])
  }

  vm_metadata_ssh_key_entries = {
    for vm_key, vm in local.vm_configs : vm_key => compact([
      for key_value in local.vm_metadata_ssh_keys[vm_key] : (trimspace(key_value) != "" ? format("%s:%s", vm.ssh_username, key_value) : "")
    ])
  }

  vm_ansible_target_hosts = {
    for vm_key, vm in google_compute_instance.vm : vm_key => try(vm.network_interface[0].access_config[0].nat_ip, null) != null ? try(vm.network_interface[0].access_config[0].nat_ip, null) : vm.network_interface[0].network_ip
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

resource "null_resource" "configure_os_login_ssh_key" {
  for_each = var.run_ansible && !var.use_metadata_ssh_keys ? local.vm_configs : {}

  depends_on = [google_compute_instance.vm]

  triggers = {
    vm_id          = google_compute_instance.vm[each.key].id
    project_id     = var.project_id
    ssh_username   = each.value.ssh_username
    ssh_public_key = each.value.ssh_public_key
    playbook_hash  = filesha256("${path.module}/ansible/site.yml")
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -eu

      if ! command -v gcloud >/dev/null 2>&1; then
        echo "gcloud CLI não encontrado no PATH do runner; pulando registro de chave no OS Login." >&2
        exit 0
      fi

      ansible_private_key_file="${var.ansible_private_key_file}"
      if [ "$${ansible_private_key_file#\~}" != "$ansible_private_key_file" ]; then
        ansible_private_key_file="$HOME$${ansible_private_key_file#\~}"
      fi

      mkdir -p "$(dirname "$ansible_private_key_file")"
      echo "Usando chave privada SSH do Ansible em $ansible_private_key_file"
      if [ ! -f "$ansible_private_key_file" ]; then
        echo "Chave privada ausente; gerando nova chave ed25519 em $ansible_private_key_file"
        ssh-keygen -t ed25519 -N '' -f "$ansible_private_key_file" -C "${each.value.ssh_username}-gcp-poc" >/dev/null 2>&1
      fi

      ansible_public_key=""
      if [ -f "$${ansible_private_key_file}.pub" ]; then
        ansible_public_key="$(cat "$${ansible_private_key_file}.pub")"
      elif [ -f "$ansible_private_key_file" ]; then
        ansible_public_key="$(ssh-keygen -y -f "$ansible_private_key_file" 2>/dev/null || true)"
      fi

      tmp_key_file="$(mktemp)"
      trap 'rm -f "$tmp_key_file"' EXIT
      {
        if [ -n "${each.value.ssh_public_key}" ]; then
          printf '%s\n' "${each.value.ssh_public_key}"
        fi
        if [ -n "$ansible_public_key" ]; then
          printf '%s\n' "$ansible_public_key"
        fi
      } | awk 'NF && !seen[$0]++' > "$tmp_key_file"

      if ! gcloud config list --format='value(core.account)' >/dev/null 2>&1; then
        echo "Falha de autenticação do gcloud. Execute 'gcloud auth login' e 'gcloud auth application-default login'." >&2
        exit 1
      fi

      if ! gcloud compute os-login ssh-keys add \
        --project="${var.project_id}" \
        --key-file="$tmp_key_file" \
        --ttl=0; then
        echo "Não foi possível registrar a chave SSH no OS Login. Verifique permissões e se o projeto aceita esse fluxo." >&2
        exit 1
      fi
    EOT
  }
}

resource "null_resource" "run_ansible" {
  for_each = var.run_ansible ? local.vm_configs : {}

  depends_on = [google_compute_instance.vm, google_compute_firewall.allow_http, google_compute_firewall.allow_ssh, null_resource.configure_os_login_ssh_key]

  triggers = {
    vm_id            = google_compute_instance.vm[each.key].id
    target_host      = local.vm_ansible_target_hosts[each.key]
    ssh_user         = each.value.ssh_username
    private_key_file = var.ansible_private_key_file
    wait_seconds     = var.ansible_wait_seconds
    max_retries      = var.ansible_max_retries
    playbook_hash    = filesha256("${path.module}/ansible/site.yml")
  }

  provisioner "local-exec" {
    working_dir = path.module
    command     = <<-EOT
      set -eu

      if ! command -v ansible-playbook >/dev/null 2>&1; then
        echo "ansible-playbook não encontrado no PATH." >&2
        exit 1
      fi

      target_host="${local.vm_ansible_target_hosts[each.key]}"
      ssh_user="${each.value.ssh_username}"
      private_key_file="${var.ansible_private_key_file}"

      if [ "$${private_key_file#\~}" != "$private_key_file" ]; then
        private_key_file="$${HOME}$${private_key_file#\~}"
      fi

      if [ ! -f "$private_key_file" ]; then
        echo "Chave privada não encontrada em $private_key_file; gerando uma nova chave ed25519" >&2
        mkdir -p "$(dirname "$private_key_file")"
        ssh-keygen -t ed25519 -N '' -f "$private_key_file" -C "${var.ansible_ssh_user}-gcp-poc" >/dev/null 2>&1
      fi

      if [ ! -f "$private_key_file" ]; then
        echo "Falha ao gerar a chave privada em $private_key_file" >&2
        exit 1
      fi

      echo "Conectando com usuário $ssh_user e chave $private_key_file"

      wait_seconds="${var.ansible_wait_seconds}"
      max_retries="${var.ansible_max_retries}"

      ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$target_host" >/dev/null 2>&1 || true
      if [ "$target_host" != "localhost" ]; then
        ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$target_host" >/dev/null 2>&1 || true
      fi

      export TARGET_HOST="$target_host"
      export ANSIBLE_SSH_USER="$ssh_user"
      export ANSIBLE_PRIVATE_KEY_FILE="$private_key_file"

      attempt=1
      while [ "$attempt" -le "$max_retries" ]; do
        echo "Tentativa $attempt/$max_retries para $target_host"

        if ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -i "$private_key_file" "$$ssh_user@$$target_host" 'true' >/dev/null 2>&1; then
          echo "SSH respondeu para $target_host"
        else
          echo "SSH ainda não respondeu para $target_host" >&2
        fi

        if ansible-playbook -i ansible/inventories/dev/hosts.yml ansible/site.yml -e "target_host=$target_host"; then
          echo "Ansible concluído com sucesso para $target_host"
          exit 0
        fi

        if [ "$attempt" -lt "$max_retries" ]; then
          echo "Falha na tentativa $attempt/$max_retries para $target_host. Aguardando $${wait_seconds}s..." >&2
          sleep "$wait_seconds"
        fi

        attempt=$((attempt + 1))
      done

      echo "Ansible falhou após $max_retries tentativas para $target_host" >&2
      exit 1
    EOT
  }
}
