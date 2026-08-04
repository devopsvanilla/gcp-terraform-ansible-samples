# ===== Autenticação no Morpheus Data =====

variable "morpheus_url" {
  type        = string
  description = "URL da instância do Morpheus Data (ex.: https://morpheus.example.com)."
}

variable "morpheus_username" {
  type        = string
  description = "Usuário do Morpheus Data. Deixe vazio se usar access_token."
  default     = ""
}

variable "morpheus_password" {
  type        = string
  description = "Senha do usuário do Morpheus Data. Deixe vazio se usar access_token."
  default     = ""
  sensitive   = true
}

variable "morpheus_access_token" {
  type        = string
  description = "Access token do Morpheus Data. Deixe vazio se usar username/password."
  default     = ""
  sensitive   = true
}

variable "morpheus_tenant_subdomain" {
  type        = string
  description = "Subdomínio do tenant do Morpheus Data, quando autenticando com username/password."
  default     = ""
}

variable "morpheus_insecure" {
  type        = bool
  description = "Permite chamadas HTTPS inseguras (certificado não validado) para o Morpheus Data."
  default     = false
}

# ===== Automação: repositório e script alvo =====

variable "repo_path" {
  type        = string
  description = "Caminho absoluto, no host de execução da task, onde este repositório está clonado."
  default     = "/opt/gcp-terraform-ansible-samples"
}

variable "poc_relative_path" {
  type        = string
  description = "Caminho relativo, a partir da raiz do repositório, até a PoC vm-nginx-terraform-ansible."
  default     = "PoCs/vm-nginx-terraform-ansible"
}

variable "add_vm_script_relative_path" {
  type        = string
  description = "Caminho relativo, a partir da raiz do repositório, até o script add-vm-to-tfvars.sh."
  default     = "scripts/add-vm-to-tfvars.sh"
}

variable "terraform_binary" {
  type        = string
  description = "Caminho ou nome do binário do Terraform disponível no host de execução da task."
  default     = "terraform"
}

# ===== Automação: alvo de execução da task no Morpheus =====

variable "task_execute_target" {
  type        = string
  description = "Alvo de execução da shell script task no Morpheus (local, remote ou resource)."
  default     = "local"

  validation {
    condition     = contains(["local", "remote", "resource"], var.task_execute_target)
    error_message = "task_execute_target deve ser \"local\", \"remote\" ou \"resource\"."
  }
}

variable "remote_target_host" {
  type        = string
  description = "Hostname ou IP do alvo remoto, quando task_execute_target = \"remote\"."
  default     = ""
}

variable "remote_target_port" {
  type        = string
  description = "Porta SSH do alvo remoto, quando task_execute_target = \"remote\"."
  default     = ""
}

variable "remote_target_username" {
  type        = string
  description = "Usuário SSH do alvo remoto, quando task_execute_target = \"remote\"."
  default     = ""
}

variable "remote_target_password" {
  type        = string
  description = "Senha SSH do alvo remoto, quando task_execute_target = \"remote\"."
  default     = ""
  sensitive   = true
}

# ===== Nomenclatura dos objetos criados no Morpheus =====

variable "blueprint_name" {
  type        = string
  description = "Nome exibido para o App Blueprint (catálogo de self-service) no Morpheus Data."
  default     = "vm-nginx-terraform-ansible"
}

variable "blueprint_description" {
  type        = string
  description = "Descrição do App Blueprint exibida no catálogo do Morpheus Data."
  default     = "Adiciona uma VM ao terraform.tfvars da PoC vm-nginx-terraform-ansible e aplica o manifesto Terraform correspondente."
}

variable "blueprint_category" {
  type        = string
  description = "Categoria do App Blueprint no catálogo do Morpheus Data."
  default     = "terraform-ansible-samples"
}

variable "blueprint_visibility" {
  type        = string
  description = "Visibilidade do App Blueprint no catálogo do Morpheus Data (public ou private)."
  default     = "private"

  validation {
    condition     = contains(["public", "private"], var.blueprint_visibility)
    error_message = "blueprint_visibility deve ser \"public\" ou \"private\"."
  }
}
