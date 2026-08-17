# Publica o App Blueprint Nativo Terraform como um item de catálogo de self-service no Morpheus Data
resource "hpe_morpheus_catalog_item_app_blueprint" "vm_nginx" {
  name        = var.blueprint_name
  description = var.blueprint_description
  category    = var.blueprint_category
  visibility  = var.blueprint_visibility
  enabled     = true

  blueprint_id    = tonumber(hpe_morpheus_app_blueprint_terraform.vm_nginx.id)
  app_spec = <<-EOT
    name: "<%= customOptions.name %>"
    group:
      id: ${var.morpheus_group_id}
    cloud:
      id: ${var.morpheus_cloud_id}
    config:
      terraform:
        commandOptions: "-var 'name=<%= customOptions.name %>' -var 'vm_name=<%= customOptions.name %>' -var 'manage_vm_external_ip_org_policy=false'"
  EOT
  option_type_ids = local.vm_nginx_option_type_ids

  content = <<-EOT
    ### ${var.blueprint_name}

    Provisiona uma instância Compute Engine com Nginx no Google Cloud Platform (GCP)
    através do engine **Terraform Nativo** do Morpheus Data.

    - **Estado (.tfstate)**: Mantido automaticamente no Cypher do Morpheus.
    - **Formulário**: Preencha os campos com os parâmetros da VM a ser criada.
  EOT
}
