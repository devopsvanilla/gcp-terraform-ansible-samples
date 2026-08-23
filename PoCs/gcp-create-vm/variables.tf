variable "poc_name" {
  type        = string
  description = "Nome lógico da PoC."
  default     = "gcp-create-vm"
}

variable "project_id" {
  type        = string
  description = "ID do projeto GCP onde os recursos serão criados."
  default     = "poc-terraform-ansible"
}

variable "gcp_credentials" {
  type        = string
  description = "Conteúdo JSON da chave de Service Account do GCP para autenticação no provider."
  default     = ""
  sensitive   = true
}

variable "region" {
  type        = string
  description = "Região GCP para a VM."
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "Zona GCP para a VM."
  default     = "us-central1-a"
}

variable "vms" {
  type = map(object({
    vm_name               = string
    machine_type_override = optional(string, "")
    machine_series        = optional(string, "e2")
    vcpu_count            = optional(number, 1)
    memory_gb             = optional(number, 1)
    disk_type             = optional(string, "pd-standard")
    disk_size_gb          = optional(number, 30)
    boot_image_project    = optional(string, "debian-cloud")
    boot_image_family     = optional(string, "debian-12")
    assign_external_ip    = optional(bool, false)
    ssh_username          = optional(string)
    ssh_public_key        = optional(string)
    user_groups           = optional(any, [])
    network_name          = optional(string)
    subnetwork_name       = optional(string)
    allowed_http_cidr     = optional(string)
    allowed_ssh_cidr      = optional(string)
  }))
  description = "Mapa de VMs a serem provisionadas no GCP."
  default     = {}
}

variable "ssh_username" {
  type        = string
  description = "Usuário Linux para metadado de SSH."
  default     = "devopsvanilla"
}

variable "ssh_public_key" {
  type        = string
  description = "Chave pública SSH no formato OpenSSH."
  default     = ""
}

variable "use_metadata_ssh_keys" {
  type        = bool
  description = "Quando true, injeta a chave SSH via metadado ssh-keys da instância."
  default     = true
}

variable "network_name" {
  type        = string
  description = "Nome da VPC para a interface de rede da VM."
  default     = "default"
}

variable "subnetwork_name" {
  type        = string
  description = "Nome da subnet. Deixe vazio para usar a sub-rede padrão da região."
  default     = ""
}

variable "allowed_http_cidr" {
  type        = string
  description = "CIDR liberado para HTTP (porta 80)."
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.allowed_http_cidr, 0)) || var.allowed_http_cidr == "" || can(regex("^<%", var.allowed_http_cidr))
    error_message = "allowed_http_cidr deve ser um CIDR válido (ex.: 0.0.0.0/0)."
  }
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR liberado para SSH (porta 22)."
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0)) || var.allowed_ssh_cidr == "" || can(regex("^<%", var.allowed_ssh_cidr))
    error_message = "allowed_ssh_cidr deve ser um CIDR válido (ex.: 203.0.113.10/32)."
  }
}

variable "name" {
  type        = string
  description = "Nome da VM enviado pelo Morpheus Form / App."
  default     = ""
}

variable "vm_name" {
  type        = string
  description = "Nome da VM caso enviado como vm_name."
  default     = ""
}

variable "app_name" {
  type        = string
  description = "Nome da Aplicação no Morpheus (injetado automaticamente pelo Morpheus como TF_VAR_app_name)."
  default     = ""
}

variable "morpheus_app_name" {
  type        = string
  description = "Nome do App Morpheus (injetado automaticamente como TF_VAR_morpheus_app_name)."
  default     = ""
}

variable "morpheus_resource_name" {
  type        = string
  description = "Nome do recurso no Morpheus."
  default     = ""
}

variable "machine_series" {
  type        = string
  description = "Série da máquina Compute Engine."
  default     = "e2"
}

variable "machine_type_override" {
  type        = string
  description = "Tipo exato de máquina Compute Engine."
  default     = "e2-micro"
}

variable "vcpu_count" {
  type        = any
  description = "Quantidade de vCPUs."
  default     = 1
}

variable "memory_gb" {
  type        = any
  description = "Memória RAM em GB."
  default     = 1
}

variable "disk_type" {
  type        = string
  description = "Tipo de disco de boot."
  default     = "pd-standard"
}

variable "disk_size_gb" {
  type        = any
  description = "Tamanho do disco em GB."
  default     = 30
}

variable "boot_image_project" {
  type        = string
  description = "Projeto da imagem de boot."
  default     = "debian-cloud"
}

variable "boot_image_family" {
  type        = string
  description = "Família da imagem de boot."
  default     = "debian-12"
}

variable "assign_external_ip" {
  type        = any
  description = "Define se a VM terá IP público."
  default     = true
}

variable "user_groups" {
  type        = any
  description = "Grupos adicionais de usuário Linux."
  default     = ["sudo"]
}
