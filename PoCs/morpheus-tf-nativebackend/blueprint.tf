# Cria o App Blueprint Terraform NATIVO no Morpheus Data.
# De acordo com a documentação oficial do Morpheus Data:
# 1. O Morpheus executa o código Terraform a partir do repositório Git vinculado.
# 2. As variáveis de entrada são injetadas a partir do Cypher secret apontado por tfvar_secret.
# 3. O estado (.tfstate) da aplicação é armazenado e mantido nativamente no Cypher do Morpheus.
resource "hpe_morpheus_app_blueprint_terraform" "vm_nginx" {
  name              = var.blueprint_name
  description       = var.blueprint_description
  category          = var.blueprint_category
  visibility        = var.blueprint_visibility
  source_type       = "repository"
  integration_id    = var.integration_id
  repository_id     = var.repository_id
  version_ref       = var.version_ref
  working_path      = var.working_path
  terraform_version = var.terraform_version
  tfvar_secret      = hpe_morpheus_cypher_secret.vm_nginx_tfvars.key
}
