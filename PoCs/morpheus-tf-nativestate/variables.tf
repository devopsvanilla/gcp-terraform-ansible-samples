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

# ===== Cloud e Group para Provisionamento do App Blueprint =====

variable "morpheus_cloud_id" {
  type        = number
  description = "ID da Cloud no Morpheus Data onde o App Blueprint será provisionado (ex.: ID da cloud GCP em Infrastructure > Clouds)."
}

variable "morpheus_group_id" {
  type        = number
  description = "ID do Group no Morpheus Data associado à Cloud de provisionamento (ex.: ID do group em Infrastructure > Groups)."
}

# ===== Integração Git e Execução do Terraform no Morpheus =====

variable "integration_id" {
  type        = number
  description = "ID da integração Git/SCM no Morpheus Data."
  default     = null
}

variable "repository_id" {
  type        = number
  description = "ID do repositório Git sincronizado no Morpheus Data."
  default     = null
}

variable "version_ref" {
  type        = string
  description = "Branch ou Tag do repositório Git que contém o manifesto Terraform (ex.: main)."
  default     = "main"
}

variable "working_path" {
  type        = string
  description = "Caminho do diretório da PoC Terraform alvo dentro do repositório Git."
  default     = "PoCs/vm-nginx-terraform-ansible"
}

variable "terraform_version" {
  type        = string
  description = "Versão do Terraform a ser executada pela engine nativa do Morpheus."
  default     = "1.6.0"
}

# ===== Metadados do App Blueprint =====

variable "blueprint_name" {
  type        = string
  description = "Nome exibido para o App Blueprint no Morpheus Data."
  default     = "vm-nginx-terraform-ansible-native"
}

variable "blueprint_description" {
  type        = string
  description = "Descrição do App Blueprint no Morpheus Data."
  default     = "Blueprint nativo Terraform para provisionamento de VM Nginx no GCP com suporte a Ansible e tfstate gerenciado no Cypher."
}

variable "blueprint_category" {
  type        = string
  description = "Categoria do App Blueprint no Morpheus Data."
  default     = "terraform-ansible-samples"
}

variable "blueprint_visibility" {
  type        = string
  description = "Visibilidade do App Blueprint no Morpheus Data (public ou private)."
  default     = "private"

  validation {
    condition     = contains(["public", "private"], var.blueprint_visibility)
    error_message = "blueprint_visibility deve ser \"public\" ou \"private\"."
  }
}

# ===== Configurações do Segredo Cypher (tfvars) =====

variable "cypher_secret_key" {
  type        = string
  description = "Chave/Caminho no Morpheus Cypher para armazenamento das tfvars (ex.: tfvars/vm-nginx-poc)."
  default     = "tfvars/vm-nginx-poc"
}

variable "cypher_secret_ttl" {
  type        = number
  description = "Tempo de vida (TTL em segundos) do segredo Cypher (0 = sem expiração)."
  default     = 0
}

# ===== Customização dos Rótulos (Labels) dos Campos do Formulário =====

variable "label_vm_name" {
  type        = string
  description = "Rótulo do campo Nome da VM no formulário."
  default     = "Nome da VM (vm_name)"
}

variable "label_machine_series" {
  type        = string
  description = "Rótulo do campo Série da Máquina no formulário."
  default     = "Série da Máquina"
}

variable "label_machine_type_override" {
  type        = string
  description = "Rótulo do campo Tipo de Máquina no formulário."
  default     = "Tipo de Máquina (Machine Type)"
}

variable "label_vcpu_count" {
  type        = string
  description = "Rótulo do campo Quantidade de vCPUs no formulário."
  default     = "Quantidade de vCPUs"
}

variable "label_memory_gb" {
  type        = string
  description = "Rótulo do campo Memória RAM no formulário."
  default     = "Memória RAM (GB)"
}

variable "label_disk_type" {
  type        = string
  description = "Rótulo do campo Tipo de Disco no formulário."
  default     = "Tipo de Disco"
}

variable "label_disk_size_gb" {
  type        = string
  description = "Rótulo do campo Tamanho do Disco no formulário."
  default     = "Tamanho do Disco (GB)"
}

variable "label_boot_image_project" {
  type        = string
  description = "Rótulo do campo Projeto da Imagem no formulário."
  default     = "Projeto da Imagem de Boot"
}

variable "label_boot_image_family" {
  type        = string
  description = "Rótulo do campo Família da Imagem no formulário."
  default     = "Família da Imagem de Boot"
}

variable "label_assign_external_ip" {
  type        = string
  description = "Rótulo do campo Atribuir IP Público no formulário."
  default     = "Atribuir IP Público Externo"
}

variable "label_ssh_username" {
  type        = string
  description = "Rótulo do campo Usuário SSH no formulário."
  default     = "Usuário SSH"
}

variable "label_ssh_public_key" {
  type        = string
  description = "Rótulo do campo Chave Pública SSH no formulário."
  default     = "Chave Pública SSH"
}

variable "label_network_name" {
  type        = string
  description = "Rótulo do campo Rede VPC no formulário."
  default     = "Rede VPC"
}

variable "label_subnetwork_name" {
  type        = string
  description = "Rótulo do campo Subnet VPC no formulário."
  default     = "Subnet VPC (Opcional - deixe vazio para utilizar a sub-rede padrão da região)"
}

variable "label_allowed_http_cidr" {
  type        = string
  description = "Rótulo do campo CIDR HTTP no formulário."
  default     = "CIDR Liberado HTTP (Porta 80)"
}

variable "label_allowed_ssh_cidr" {
  type        = string
  description = "Rótulo do campo CIDR SSH no formulário."
  default     = "CIDR Liberado SSH (Porta 22)"
}

variable "label_run_ansible" {
  type        = string
  description = "Rótulo do campo Executar Ansible no formulário."
  default     = "Executar Ansible (Instalação Nginx)"
}

variable "label_user_groups" {
  type        = string
  description = "Rótulo do campo Grupos de Usuários no formulário."
  default     = "Grupos Linux Adicionais (separados por vírgula)"
}


# ===== Parâmetros da VM e Ambiente GCP (Sem valores padrão para os opcionais) =====
# Se estes parâmetros não forem definidos no terraform.tfvars, os campos do formulário no Morpheus
# serão exibidos em branco (sem valor pré-preenchido).

variable "poc_name" {
  type        = string
  description = "Nome lógico da PoC."
  default     = "vm-nginx-terraform-ansible"
}

variable "project_id" {
  type        = string
  description = "ID do projeto GCP onde os recursos serão criados."
  default     = null
}

variable "gcp_credentials" {
  type        = string
  description = "Conteúdo JSON da chave da Service Account GCP. Se mantido nulo, buscará do Cypher em secret/gcp-terraform-ansible-samples."
  default     = null
  sensitive   = true
}

variable "region" {
  type        = string
  description = "Região GCP para os recursos."
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "Zona GCP para a VM."
  default     = "us-central1-a"
}

variable "vm_name" {
  type        = string
  description = "Nome da VM a ser criada na execução do Blueprint."
  default     = null
}

variable "machine_series" {
  type        = string
  description = "Série da máquina Compute Engine (ex.: e2, n2)."
  default     = null
}

variable "machine_type_override" {
  type        = string
  description = "Tipo exato de máquina Compute Engine (ex.: e2-micro, e2-medium)."
  default     = null
}

variable "vcpu_count" {
  type        = number
  description = "Quantidade de vCPUs da máquina."
  default     = null
}

variable "memory_gb" {
  type        = number
  description = "Quantidade de memória RAM em GB."
  default     = null
}

variable "disk_type" {
  type        = string
  description = "Tipo do disco de boot (ex.: pd-standard, pd-ssd)."
  default     = null
}

variable "disk_size_gb" {
  type        = number
  description = "Tamanho do disco de boot em GB."
  default     = null
}

variable "boot_image_project" {
  type        = string
  description = "Projeto GCP da imagem de boot."
  default     = null
}

variable "boot_image_family" {
  type        = string
  description = "Família da imagem de boot."
  default     = null
}

variable "assign_external_ip" {
  type        = bool
  description = "Define se a VM receberá um IP público externo."
  default     = null
}

variable "manage_vm_external_ip_org_policy" {
  type        = bool
  description = "Gerencia a restrição constraints/compute.vmExternalIpAccess na Org Policy para a VM."
  default     = null
}

variable "ssh_username" {
  type        = string
  description = "Usuário Linux para injeção de chave SSH nos metadados."
  default     = null
}

variable "ssh_public_key" {
  type        = string
  description = "Chave pública SSH no formato OpenSSH para acesso à VM."
  default     = null
}

variable "user_groups" {
  type        = string
  description = "Grupos Linux adicionais separados por vírgula (ex.: sudo, www-data)."
  default     = "sudo,www-data"
}

variable "network_name" {
  type        = string
  description = "Nome da rede VPC onde a interface de rede da VM será conectada."
  default     = null
}

variable "subnetwork_name" {
  type        = string
  description = "Nome da subnet VPC (deixe vazio para automático/default)."
  default     = null
}

variable "allowed_http_cidr" {
  type        = string
  description = "CIDR liberado para acesso HTTP (porta 80)."
  default     = null
}

variable "allowed_ssh_cidr" {
  type        = string
  description = "CIDR liberado para acesso SSH (porta 22)."
  default     = null
}

variable "use_metadata_ssh_keys" {
  type        = bool
  description = "Quando true, injeta a chave SSH via metadado da instância."
  default     = null
}

variable "run_ansible" {
  type        = bool
  description = "Quando true, o Terraform dispara a automação Ansible para provisionamento do Nginx."
  default     = null
}

variable "ansible_wait_seconds" {
  type        = number
  description = "Tempo em segundos entre tentativas do Ansible."
  default     = null
}

variable "ansible_max_retries" {
  type        = number
  description = "Número máximo de tentativas de execução do Ansible."
  default     = null
}

variable "ansible_private_key_file" {
  type        = string
  description = "Caminho do arquivo de chave privada SSH usada pelo Ansible."
  default     = null
}

variable "ansible_ssh_user" {
  type        = string
  description = "Usuário SSH utilizado pelo Ansible."
  default     = null
}

variable "ansible_private_key" {
  type        = string
  description = "Conteúdo da chave privada SSH usada pelo Ansible. Armazenada de forma segura no Cypher no segredo secret/ansible-private-key."
  default     = null
  sensitive   = true
}

