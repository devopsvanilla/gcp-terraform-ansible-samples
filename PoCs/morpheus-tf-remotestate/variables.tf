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

# ===== Automação: repositório Git e script alvo no Morpheus =====

variable "task_source_type" {
  type        = string
  description = "Origem do script da task no Morpheus Data (repository, local ou url)."
  default     = "repository"

  validation {
    condition     = contains(["local", "repository", "url"], var.task_source_type)
    error_message = "task_source_type deve ser \"local\", \"repository\" ou \"url\"."
  }
}

variable "task_repository_id" {
  type        = number
  description = "ID numérico do repositório Git configurado/sincronizado no Morpheus Data. Obrigatório quando task_source_type = \"repository\"."
  default     = null
}

variable "git_integration_name" {
  type        = string
  description = "Nome da integração Git no Morpheus Data para busca automática do ID do repositório (opcional se task_repository_id for definido)."
  default     = ""
}

variable "git_repository_name" {
  type        = string
  description = "Nome do repositório na integração Git no Morpheus Data (opcional se task_repository_id for definido)."
  default     = ""
}

variable "task_script_path" {
  type        = string
  description = "Caminho de execução do script wrapper dentro do repositório Git (ex.: PoCs/morpheus-tf-remotestate/templates/add_vm_and_apply.sh)."
  default     = "PoCs/morpheus-tf-remotestate/templates/add_vm_and_apply.sh"
}

variable "remove_task_script_path" {
  type        = string
  description = "Caminho de execução do script de remoção/teardown dentro do repositório Git (ex.: PoCs/morpheus-tf-remotestate/templates/remove_vm_and_apply.sh)."
  default     = "PoCs/morpheus-tf-remotestate/templates/remove_vm_and_apply.sh"
}

variable "task_version_ref" {
  type        = string
  description = "Branch ou Tag do repositório Git para obtenção do script no Morpheus (ex.: main)."
  default     = "main"
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

variable "task_local_repository_id" {
  type        = string
  description = "ID do repositório Git para o contexto de execução local (GIT REPO). Se nulo, utiliza o valor de task_repository_id."
  default     = null
}

variable "task_local_repository_ref" {
  type        = string
  description = "Branch ou Tag para o contexto de execução local (GIT REF)."
  default     = "main"
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

variable "workflow_name" {
  type        = string
  description = "Nome exibido para o Workflow Operacional no Morpheus Data."
  default     = "gcp-create-vm-add-and-apply"
}

variable "blueprint_name" {
  type        = string
  description = "Nome exibido para o App Blueprint (catálogo de self-service) no Morpheus Data."
  default     = "gcp-create-vm-gcstate"
}

variable "blueprint_description" {
  type        = string
  description = "Descrição do App Blueprint exibida no catálogo do Morpheus Data."
  default     = "Adiciona uma VM ao terraform.tfvars no Cypher da PoC gcp-create-vm-gcstate e aplica o manifesto Terraform com remote state no GCS."
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

# ===== Gerenciamento de Variáveis no Cypher e GCP =====

variable "project_id" {
  type        = string
  description = "ID do projeto GCP padrão para a infraestrutura."
  default     = "poc-terraform-ansible"
}

variable "cypher_tfvars_key" {
  type        = string
  description = "Chave no Morpheus Cypher onde o conteúdo de terraform.tfvars será armazenado (sem o prefixo secret/, pois o recurso hpe_morpheus_cypher_secret já o adiciona)."
  default     = "tfvars-gcp-create-vm-gcstate"
}

variable "cypher_tfvars_ttl" {
  type        = number
  description = "Tempo de vida (TTL) em segundos para o segredo de tfvars no Cypher (0 = sem expiração)."
  default     = 0
}

