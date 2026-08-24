# App Blueprint do Morpheus Data conectado ao repositório Git e Cypher tfvars
resource "hpe_morpheus_app_blueprint_terraform" "vm_nginx" {
  name           = var.blueprint_name
  description    = var.blueprint_description
  category       = var.blueprint_category
  source_type    = "repository"
  integration_id = var.integration_id
  repository_id  = var.repository_id
  version_ref    = var.version_ref
  working_path   = var.working_path
  tfvar_secret   = hpe_morpheus_cypher_secret.vm_nginx_tfvars.key
}
