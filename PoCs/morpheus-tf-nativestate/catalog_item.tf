# Publica o App Blueprint Nativo como Item de Catálogo de Self-Service no Morpheus
resource "hpe_morpheus_catalog_item_app_blueprint" "vm_nginx" {
  name         = var.blueprint_name
  description  = var.blueprint_description
  category     = var.blueprint_category
  visibility   = var.blueprint_visibility
  blueprint_id = tonumber(hpe_morpheus_app_blueprint_terraform.vm_nginx.id)
  enabled      = true

  option_type_ids = local.vm_nginx_option_type_ids

  app_spec = jsonencode({
    name = "<%= customOptions.name ?: customOptions.vm_name ?: 'vm-gcp-poc' %>"
    config = {
      name = "<%= customOptions.name ?: customOptions.vm_name ?: 'vm-gcp-poc' %>"
      customOptions = {
        for k in local.all_option_type_field_names : k => "<%= customOptions.${k} %>"
      }
    }
  })

  content = <<-EOT
    ### ${var.blueprint_name}

    Provisiona instâncias Compute Engine no Google Cloud Platform (GCP) com **App Blueprint Nativo**.
    
    - **Painel Nativo**: Acesso à árvore de recursos e estado (.tfstate) na aba *Provisioning > Apps*.
    - **Drift Detection**: Varredura e correção nativa de desvios de configuração.
    - **Dimensionamento Dinâmico**: vCPUs, Memória RAM e Tamanho de Disco totalmente customizáveis pelo formulário.
  EOT
}
