# Publica o workflow operacional como um item de catálogo de self-service no Morpheus Data
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

    Provisiona instâncias Compute Engine no Google Cloud Platform (GCP) com formulário
    dinâmico (disco, vCPU, RAM, etc.) e **estado mantido nativamente no Morpheus Cypher**.

    - **Estado (.tfstate)**: Mantido automaticamente no Cypher do Morpheus.
    - **Parâmetros**: Preencha o formulário com a quantidade desejada de vCPUs, RAM e tamanho de disco.
  EOT
}

# Publica o item de catálogo para remoção de VM sob demanda
resource "hpe_morpheus_catalog_item_workflow" "vm_nginx_remove_and_apply" {
  name         = "${var.blueprint_name}-remover-vm"
  description  = "Remove uma VM existente do terraform.tfvars no Cypher e desprovisiona os recursos via Terraform."
  category     = var.blueprint_category
  visibility   = var.blueprint_visibility
  context_type = "appliance"
  enabled      = true

  workflow_id = tonumber(hpe_morpheus_workflow_operational.vm_nginx_remove_and_apply.id)
  option_type_ids = [
    tonumber(hpe_morpheus_option_type_text.vm_name.id),
  ]

  content = <<-EOT
    ### Remover VM - ${var.blueprint_name}

    Remove a entrada da VM do `terraform.tfvars` no Cypher e executa `terraform apply`
    para destruir os recursos no GCP e atualizar o `tfstate` no Cypher do Morpheus.

    Informe o **Nome da VM** que deseja excluir.
  EOT
}
