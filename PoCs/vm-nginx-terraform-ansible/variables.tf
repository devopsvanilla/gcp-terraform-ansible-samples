variable "poc_name" {
  type        = string
  description = "Nome lógico da PoC."
}

variable "project_id" {
  type        = string
  description = "ID do projeto GCP onde os recursos serão criados."
}

variable "region" {
  type        = string
  description = "Região GCP para a PoC."
}

variable "zone" {
  type        = string
  description = "Zona GCP para a VM."
}

variable "vms" {
  type = map(object({
    vm_name                          = string
    machine_type_override            = optional(string, "")
    machine_series                   = optional(string, "e2")
    vcpu_count                       = optional(number, 1)
    memory_gb                        = optional(number, 1)
    disk_type                        = optional(string, "pd-standard")
    disk_size_gb                     = optional(number, 30)
    boot_image_project               = optional(string, "debian-cloud")
    boot_image_family                = optional(string, "debian-12")
    assign_external_ip               = optional(bool, false)
    ssh_username                     = optional(string)
    ssh_public_key                   = optional(string)
    user_groups                      = optional(list(string), [])
    network_name                     = optional(string)
    subnetwork_name                  = optional(string)
    allowed_http_cidr                = optional(string)
    allowed_ssh_cidr                 = optional(string)
    manage_vm_external_ip_org_policy = optional(bool)
  }))
  description = "Mapa de VMs da PoC. Cada entrada pode habilitar ou não IP público individualmente e, quando assign_external_ip = true, a allowlist da Org Policy é calculada automaticamente para a VM."

  validation {
    condition     = length(var.vms) > 0
    error_message = "Defina ao menos uma VM em vms."
  }

  validation {
    condition     = alltrue([for vm in values(var.vms) : can(tobool(vm.assign_external_ip))])
    error_message = "Cada assign_external_ip em vms deve ser true ou false."
  }

  validation {
    condition     = length(distinct([for vm in values(var.vms) : vm.vm_name])) == length(values(var.vms))
    error_message = "Cada vm_name em vms deve ser único no projeto/zona da PoC."
  }
}

variable "manage_vm_external_ip_org_policy" {
  type        = bool
  description = "Quando true, a PoC gerencia no projeto a policy constraints/compute.vmExternalIpAccess em modo restrito para as VMs definidas em vms com assign_external_ip = true."
  default     = true
}

variable "ssh_username" {
  type        = string
  description = "Usuário Linux para metadado de SSH."
}

variable "ssh_public_key" {
  type        = string
  description = "Chave pública SSH no formato OpenSSH."
}

variable "use_metadata_ssh_keys" {
  type        = bool
  description = "Quando true, injeta a chave SSH via metadado ssh-keys da instância. Desative em projetos com OS Login obrigatório (constraints/compute.requireOsLogin)."
  default     = false
}

variable "network_name" {
  type        = string
  description = "Nome da VPC para a interface de rede da VM."
}

variable "subnetwork_name" {
  type        = string
  description = "Nome da subnet. Deixe vazio para não definir explicitamente."
  default     = ""
}

variable "allowed_http_cidr" {
  type        = string
  description = "CIDR liberado para HTTP (porta 80)."

  validation {
    condition     = can(cidrhost(var.allowed_http_cidr, 0))
    error_message = "allowed_http_cidr deve ser um CIDR válido (ex.: 0.0.0.0/0)."
  }
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR liberado para SSH (porta 22)."

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "allowed_ssh_cidr deve ser um CIDR válido (ex.: 203.0.113.10/32)."
  }
}

variable "run_ansible" {
  type        = bool
  description = "Quando true, o Terraform executa o playbook do Ansible após a criação das VMs."
  default     = true
}

variable "ansible_wait_seconds" {
  type        = number
  description = "Tempo em segundos entre tentativas de execução do playbook do Ansible."
  default     = 15

  validation {
    condition     = var.ansible_wait_seconds > 0
    error_message = "ansible_wait_seconds deve ser maior que zero."
  }
}

variable "ansible_max_retries" {
  type        = number
  description = "Número máximo de tentativas para executar o playbook do Ansible."
  default     = 10

  validation {
    condition     = var.ansible_max_retries >= 1
    error_message = "ansible_max_retries deve ser maior ou igual a 1."
  }
}

variable "ansible_private_key_file" {
  type        = string
  description = "Caminho da chave privada SSH usada pelo Ansible. Aceita caminho absoluto ou o padrão ~/.ssh/id_ed25519."
  default     = "~/.ssh/id_ed25519"
}

variable "ansible_ssh_user" {
  type        = string
  description = "Usuário SSH/OS Login usado pelo Ansible para conectar na VM."
  default     = "devopsvanillaofficial_gmail_com"
}
