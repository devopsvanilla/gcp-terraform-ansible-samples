# Cada option_type abaixo corresponde a um campo no formulário de self-service
# exibido ao solicitar a VM no Catálogo do Morpheus Data.

resource "hpe_morpheus_option_type_text" "vm_name" {
  name        = "vm-nginx-vm-name"
  field_name  = "vmName"
  field_label = "Nome da VM (vm_name)"
  description = "Nome real da instância Compute Engine que será criada."
  required    = true
}

resource "hpe_morpheus_option_type_text" "machine_type_override" {
  name          = "vm-nginx-machine-type-override"
  field_name    = "machineTypeOverride"
  field_label   = "Machine type"
  description   = "Tipo de máquina completo (ex.: e2-micro). Deixe vazio para montar a partir de série/vCPU/RAM."
  default_value = "e2-micro"
  required      = false
}

resource "hpe_morpheus_option_type_text" "machine_series" {
  name          = "vm-nginx-machine-series"
  field_name    = "machineSeries"
  field_label   = "Série da máquina"
  description   = "Série da máquina (ex.: e2), usada quando machineTypeOverride estiver vazio."
  default_value = "e2"
  required      = false
}

resource "hpe_morpheus_option_type_number" "vcpu_count" {
  name          = "vm-nginx-vcpu-count"
  field_name    = "vcpuCount"
  field_label   = "Quantidade de vCPUs"
  description   = "Usado quando machineTypeOverride estiver vazio."
  default_value = "1"
  required      = false
}

resource "hpe_morpheus_option_type_number" "memory_gb" {
  name          = "vm-nginx-memory-gb"
  field_name    = "memoryGb"
  field_label   = "Memória (GB)"
  description   = "Usado quando machineTypeOverride estiver vazio."
  default_value = "1"
  required      = false
}

resource "hpe_morpheus_option_type_text" "disk_type" {
  name          = "vm-nginx-disk-type"
  field_name    = "diskType"
  field_label   = "Tipo de disco"
  description   = "Tipo do disco de boot (ex.: pd-standard, pd-ssd, pd-balanced)."
  default_value = "pd-standard"
  required      = false
}

resource "hpe_morpheus_option_type_number" "disk_size_gb" {
  name          = "vm-nginx-disk-size-gb"
  field_name    = "diskSizeGb"
  field_label   = "Tamanho do disco (GB)"
  default_value = "30"
  required      = false
}

resource "hpe_morpheus_option_type_text" "boot_image_project" {
  name          = "vm-nginx-boot-image-project"
  field_name    = "bootImageProject"
  field_label   = "Projeto da imagem de boot"
  default_value = "debian-cloud"
  required      = false
}

resource "hpe_morpheus_option_type_text" "boot_image_family" {
  name          = "vm-nginx-boot-image-family"
  field_name    = "bootImageFamily"
  field_label   = "Família da imagem de boot"
  default_value = "debian-12"
  required      = false
}

resource "hpe_morpheus_option_type_checkbox" "assign_external_ip" {
  name            = "vm-nginx-assign-external-ip"
  field_name      = "assignExternalIp"
  field_label     = "Atribuir IP externo?"
  default_checked = true
}

resource "hpe_morpheus_option_type_text" "ssh_username" {
  name        = "vm-nginx-ssh-username"
  field_name  = "sshUsername"
  field_label = "Usuário SSH remoto"
  description = "Usuário criado na VM via startup script e usado para acesso SSH."
  required    = false
}

resource "hpe_morpheus_option_type_text" "ssh_public_key" {
  name        = "vm-nginx-ssh-public-key"
  field_name  = "sshPublicKey"
  field_label = "Chave pública SSH"
  description = "Chave pública no formato OpenSSH injetada como metadado da instância."
  required    = false
}

resource "hpe_morpheus_option_type_text" "network_name" {
  name          = "vm-nginx-network-name"
  field_name    = "networkName"
  field_label   = "Rede (VPC)"
  default_value = "default"
  required      = false
}

resource "hpe_morpheus_option_type_text" "subnetwork_name" {
  name        = "vm-nginx-subnetwork-name"
  field_name  = "subnetworkName"
  field_label = "Sub-rede"
  description = "Deixe vazio para usar a sub-rede padrão definida no manifesto."
  required    = false
}

resource "hpe_morpheus_option_type_text" "allowed_http_cidr" {
  name          = "vm-nginx-allowed-http-cidr"
  field_name    = "allowedHttpCidr"
  field_label   = "CIDR liberado para HTTP (80)"
  default_value = "0.0.0.0/0"
  required      = false
}

resource "hpe_morpheus_option_type_text" "allowed_ssh_cidr" {
  name        = "vm-nginx-allowed-ssh-cidr"
  field_name  = "allowedSshCidr"
  field_label = "CIDR liberado para SSH (22)"
  description = "Por segurança, use seu IP público com /32 ou o CIDR da sua rede de administração."
  required    = true
}

resource "hpe_morpheus_option_type_checkbox" "manage_vm_external_ip_org_policy" {
  name            = "vm-nginx-manage-org-policy"
  field_name      = "manageVmExternalIpOrgPolicy"
  field_label     = "Gerenciar Org Policy de IP externo?"
  default_checked = false
}

resource "hpe_morpheus_option_type_text" "user_groups" {
  name        = "vm-nginx-user-groups"
  field_name  = "userGroups"
  field_label = "Grupos do usuário remoto"
  description = "Lista de grupos separados por vírgula (ex.: sudo,docker). Deixe vazio para nenhum grupo."
  required    = false
}
