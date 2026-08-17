variable "poc_name" {
  type        = string
  description = "Nome lógico da PoC."
  default     = "vm-nginx-terraform-ansible"
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
  description = "Região GCP para a PoC."
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "Zona GCP para a VM."
  default     = "us-central1-a"
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
    user_groups                      = optional(any, [])
    network_name                     = optional(string)
    subnetwork_name                  = optional(string)
    allowed_http_cidr                = optional(string)
    allowed_ssh_cidr                 = optional(string)
    manage_vm_external_ip_org_policy = optional(bool)
  }))
  description = "Mapa de VMs da PoC. Cada entrada pode habilitar ou não IP público individualmente e, quando assign_external_ip = true, a allowlist da Org Policy é calculada automaticamente para a VM."
  default = {
    vm_nginx_poc = {
      vm_name            = "vm-nginx-poc"
      machine_series     = "e2"
      assign_external_ip = true
    }
  }
}

variable "manage_vm_external_ip_org_policy" {
  type        = bool
  description = "Quando true, a PoC gerencia no projeto a policy constraints/compute.vmExternalIpAccess em modo restrito para as VMs definidas em vms com assign_external_ip = true."
  default     = false
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
  description = "Quando true, injeta a chave SSH via metadado ssh-keys da instância. Desative em projetos com OS Login obrigatório (constraints/compute.requireOsLogin)."
  default     = true
}

variable "network_name" {
  type        = string
  description = "Nome da VPC para a interface de rede da VM."
  default     = "default"
}

variable "subnetwork_name" {
  type        = string
  description = "Nome da subnet. Deixe vazio para não definir explicitamente."
  default     = ""
}

variable "allowed_http_cidr" {
  type        = string
  description = "CIDR liberado para HTTP (porta 80)."
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.allowed_http_cidr, 0))
    error_message = "allowed_http_cidr deve ser um CIDR válido (ex.: 0.0.0.0/0)."
  }
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR liberado para SSH (porta 22)."
  default     = "0.0.0.0/0"

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

# ===== Variáveis Flat enviadas pelos formulários de Catálogo do Morpheus =====
variable "name" {
  type        = string
  description = "Nome da VM enviado pelo Morpheus Form."
  default     = ""
}

variable "vm_name" {
  type        = string
  description = "Nome da VM caso enviado como vm_name."
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
  type        = number
  description = "Quantidade de vCPUs."
  default     = 1
}

variable "memory_gb" {
  type        = number
  description = "Memória RAM em GB."
  default     = 1
}

variable "disk_type" {
  type        = string
  description = "Tipo de disco de boot."
  default     = "pd-standard"
}

variable "disk_size_gb" {
  type        = number
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
  type        = bool
  description = "Define se a VM terá IP público."
  default     = true
}

variable "user_groups" {
  type        = list(string)
  description = "Grupos adicionais de usuário Linux."
  default     = ["sudo", "www-data"]
}
