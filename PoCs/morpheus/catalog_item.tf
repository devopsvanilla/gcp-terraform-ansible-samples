# Publica o workflow operacional como um item de catálogo de self-service
# (o equivalente funcional, neste repositório, a um "App Blueprint" com
# formulário — ver README.md, seção "O que será implantado", para o motivo
# de não usar o recurso hpe_morpheus_app_blueprint_terraform diretamente).
resource "hpe_morpheus_catalog_item_workflow" "vm_nginx_add_and_apply" {
  name         = var.blueprint_name
  description  = var.blueprint_description
  category     = var.blueprint_category
  visibility   = var.blueprint_visibility
  context_type = "appliance"
  enabled      = true

  workflow_id     = tonumber(hpe_morpheus_workflow_operational.vm_nginx_add_and_apply.id)
  option_type_ids = local.vm_nginx_option_type_ids

  content = <<-EOT
    ### ${var.blueprint_name}

    Adiciona uma nova VM ao `terraform.tfvars` da PoC `vm-nginx-terraform-ansible`
    e executa `terraform apply` no manifesto correspondente.

    Preencha os campos do formulário com os mesmos valores que seriam passados
    para `scripts/add-vm-to-tfvars.sh`.
  EOT
}
