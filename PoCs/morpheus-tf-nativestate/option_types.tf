# Formulário do Morpheus Data (Option Types):
# Todas as opções abaixo criam campos de preenchimento OBRIGATÓRIO (required = true)
# na interface gráfica do Morpheus Data para o App Blueprint, com exceção da subnet VPC (opcional).

resource "hpe_morpheus_option_type_text" "vm_name" {
  name        = "vm-native-vm-name"
  field_name  = "vm_name"
  field_label = var.label_vm_name
  description = "Nome da instância Compute Engine no GCP (deve ser único no Morpheus)."
  placeholder = "ex: vm-gcp-poc2"
  export_meta = true
  required    = true
}

resource "hpe_morpheus_option_type_text" "machine_series" {
  name          = "vm-native-machine-series"
  field_name    = "machine_series"
  field_label   = var.label_machine_series
  description   = "Série da família de máquinas Compute Engine (ex.: e2, n2)."
  default_value = var.machine_series
  required      = true
}

resource "hpe_morpheus_option_type_text" "machine_type_override" {
  name          = "vm-native-machine-type-override"
  field_name    = "machine_type_override"
  field_label   = var.label_machine_type_override
  description   = "Tipo exato de máquina no GCP (ex.: e2-micro, e2-medium)."
  default_value = var.machine_type_override
  required      = true
}

resource "hpe_morpheus_option_type_number" "vcpu_count" {
  name          = "vm-native-vcpu-count"
  field_name    = "vcpu_count"
  field_label   = var.label_vcpu_count
  description   = "Número de vCPUs da instância."
  default_value = var.vcpu_count != null ? tostring(var.vcpu_count) : null
  required      = true
}

resource "hpe_morpheus_option_type_number" "memory_gb" {
  name          = "vm-native-memory-gb"
  field_name    = "memory_gb"
  field_label   = var.label_memory_gb
  description   = "Memória RAM da instância em gigabytes."
  default_value = var.memory_gb != null ? tostring(var.memory_gb) : null
  required      = true
}

resource "hpe_morpheus_option_type_text" "disk_type" {
  name          = "vm-native-disk-type"
  field_name    = "disk_type"
  field_label   = var.label_disk_type
  description   = "Tipo do disco de boot (pd-standard, pd-ssd, pd-balanced)."
  default_value = var.disk_type
  required      = true
}

resource "hpe_morpheus_option_type_number" "disk_size_gb" {
  name          = "vm-native-disk-size-gb"
  field_name    = "disk_size_gb"
  field_label   = var.label_disk_size_gb
  description   = "Capacidade em GB do disco de boot."
  default_value = var.disk_size_gb != null ? tostring(var.disk_size_gb) : null
  required      = true
}

resource "hpe_morpheus_option_type_text" "boot_image_project" {
  name          = "vm-native-boot-image-project"
  field_name    = "boot_image_project"
  field_label   = var.label_boot_image_project
  description   = "Projeto da imagem de boot."
  default_value = var.boot_image_project
  required      = true
}

resource "hpe_morpheus_option_type_text" "boot_image_family" {
  name          = "vm-native-boot-image-family"
  field_name    = "boot_image_family"
  field_label   = var.label_boot_image_family
  description   = "Família da imagem de boot."
  default_value = var.boot_image_family
  required      = true
}

resource "hpe_morpheus_option_type_checkbox" "assign_external_ip" {
  name            = "vm-native-assign-external-ip"
  field_name      = "assign_external_ip"
  field_label     = var.label_assign_external_ip
  default_checked = var.assign_external_ip != null ? var.assign_external_ip : false
}

resource "hpe_morpheus_option_type_text" "ssh_username" {
  name          = "vm-native-ssh-username"
  field_name    = "ssh_username"
  field_label   = var.label_ssh_username
  description   = "Usuário Linux para injeção de chave SSH."
  default_value = var.ssh_username
  required      = true
}

resource "hpe_morpheus_option_type_textarea" "ssh_public_key" {
  name          = "vm-native-ssh-public-key"
  field_name    = "ssh_public_key"
  field_label   = var.label_ssh_public_key
  description   = "Chave pública SSH no formato OpenSSH."
  default_value = var.ssh_public_key
  rows          = "3"
  required      = true
}

resource "hpe_morpheus_option_type_text" "user_groups" {
  name          = "vm-native-user-groups"
  field_name    = "user_groups"
  field_label   = var.label_user_groups
  description   = "Grupos adicionais no Linux (ex.: sudo, www-data)."
  default_value = var.user_groups
  required      = false
}

resource "hpe_morpheus_option_type_text" "network_name" {
  name          = "vm-native-network-name"
  field_name    = "network_name"
  field_label   = var.label_network_name
  default_value = var.network_name
  required      = true
}

resource "hpe_morpheus_option_type_text" "subnetwork_name" {
  name          = "vm-native-subnetwork-name"
  field_name    = "subnetwork_name"
  field_label   = var.label_subnetwork_name
  description   = "Deixe vazio para utilizar a sub-rede padrão da região."
  default_value = var.subnetwork_name
  required      = false
}

resource "hpe_morpheus_option_type_text" "allowed_http_cidr" {
  name          = "vm-native-allowed-http-cidr"
  field_name    = "allowed_http_cidr"
  field_label   = var.label_allowed_http_cidr
  default_value = var.allowed_http_cidr
  required      = true
}

resource "hpe_morpheus_option_type_text" "allowed_ssh_cidr" {
  name          = "vm-native-allowed-ssh-cidr"
  field_name    = "allowed_ssh_cidr"
  field_label   = var.label_allowed_ssh_cidr
  description   = "CIDR de acesso à administração SSH (ex.: 198.51.100.25/32)."
  default_value = var.allowed_ssh_cidr
  required      = true
}

locals {
  vm_nginx_option_type_ids = [
    tonumber(hpe_morpheus_option_type_text.vm_name.id),
    tonumber(hpe_morpheus_option_type_text.machine_series.id),
    tonumber(hpe_morpheus_option_type_text.machine_type_override.id),
    tonumber(hpe_morpheus_option_type_number.vcpu_count.id),
    tonumber(hpe_morpheus_option_type_number.memory_gb.id),
    tonumber(hpe_morpheus_option_type_text.disk_type.id),
    tonumber(hpe_morpheus_option_type_number.disk_size_gb.id),
    tonumber(hpe_morpheus_option_type_text.boot_image_project.id),
    tonumber(hpe_morpheus_option_type_text.boot_image_family.id),
    tonumber(hpe_morpheus_option_type_checkbox.assign_external_ip.id),
    tonumber(hpe_morpheus_option_type_text.ssh_username.id),
    tonumber(hpe_morpheus_option_type_textarea.ssh_public_key.id),
    tonumber(hpe_morpheus_option_type_text.user_groups.id),
    tonumber(hpe_morpheus_option_type_text.network_name.id),
    tonumber(hpe_morpheus_option_type_text.subnetwork_name.id),
    tonumber(hpe_morpheus_option_type_text.allowed_http_cidr.id),
    tonumber(hpe_morpheus_option_type_text.allowed_ssh_cidr.id)
  ]

  all_option_type_field_names = [
    "name",
    "vm_name",
    "machine_series",
    "machine_type_override",
    "vcpu_count",
    "memory_gb",
    "disk_type",
    "disk_size_gb",
    "boot_image_project",
    "boot_image_family",
    "assign_external_ip",
    "ssh_username",
    "ssh_public_key",
    "user_groups",
    "network_name",
    "subnetwork_name",
    "allowed_http_cidr",
    "allowed_ssh_cidr"
  ]
}
