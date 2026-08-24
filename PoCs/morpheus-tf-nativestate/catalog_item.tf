# Publica o App Blueprint Nativo como Item de Catálogo de Self-Service no Morpheus
resource "hpe_morpheus_catalog_item_app_blueprint" "vm_nginx" {
  name         = var.blueprint_name
  description  = var.blueprint_description
  category     = var.blueprint_category
  visibility   = var.blueprint_visibility
  blueprint_id = tonumber(hpe_morpheus_app_blueprint_terraform.vm_nginx.id)
  enabled      = true

  option_type_ids = local.vm_nginx_option_type_ids

  app_spec = <<-EOT
    name: <%=customOptions.vm_name%>
    group:
      id: ${var.morpheus_group_id}
    cloud:
      id: ${var.morpheus_cloud_id}
    config:
      customOptions:
        vm_name: <%=customOptions.vm_name%>
        machine_series: <%=customOptions.machine_series%>
        machine_type_override: <%=customOptions.machine_type_override%>
        vcpu_count: <%=customOptions.vcpu_count%>
        memory_gb: <%=customOptions.memory_gb%>
        disk_type: <%=customOptions.disk_type%>
        disk_size_gb: <%=customOptions.disk_size_gb%>
        boot_image_project: <%=customOptions.boot_image_project%>
        boot_image_family: <%=customOptions.boot_image_family%>
        assign_external_ip: <%=customOptions.assign_external_ip%>
        ssh_username: <%=customOptions.ssh_username%>
        ssh_public_key: <%=customOptions.ssh_public_key%>
        network_name: <%=customOptions.network_name%>
        subnetwork_name: <%=customOptions.subnetwork_name%>
        allowed_http_cidr: <%=customOptions.allowed_http_cidr%>
        allowed_ssh_cidr: <%=customOptions.allowed_ssh_cidr%>
  EOT

  content = <<-EOT
    ### ${var.blueprint_name}

    Provisiona instâncias Compute Engine no Google Cloud Platform (GCP) com **App Blueprint Nativo**.
    
    - **Painel Nativo**: Acesso à árvore de recursos e estado (.tfstate) na aba *Provisioning > Apps*.
    - **Drift Detection**: Varredura e correção nativa de desvios de configuração.
    - **Dimensionamento Dinâmico**: vCPUs, Memória RAM e Tamanho de Disco totalmente customizáveis pelo formulário.
  EOT
}
