# Publica o App Blueprint Nativo Terraform como um item de catálogo de self-service no Morpheus Data
resource "hpe_morpheus_catalog_item_app_blueprint" "vm_nginx" {
  name        = var.blueprint_name
  description = var.blueprint_description
  category    = var.blueprint_category
  visibility  = var.blueprint_visibility
  enabled     = true

  blueprint_id    = tonumber(hpe_morpheus_app_blueprint_terraform.vm_nginx.id)
  app_spec        = <<-EOT
    name: '<%= customOptions.vm_name %>'
    group:
      id: ${var.morpheus_group_id}
    cloud:
      id: ${var.morpheus_cloud_id}
    config:
      name: '<%= customOptions.vm_name %>'
      vm_name: '<%= customOptions.vm_name %>'
      app_name: '<%= customOptions.vm_name %>'
      machine_series: '<%= customOptions.machine_series %>'
      machine_type_override: '<%= customOptions.machine_type_override %>'
      vcpu_count: '<%= customOptions.vcpu_count %>'
      memory_gb: '<%= customOptions.memory_gb %>'
      disk_type: '<%= customOptions.disk_type %>'
      disk_size_gb: '<%= customOptions.disk_size_gb %>'
      boot_image_project: '<%= customOptions.boot_image_project %>'
      boot_image_family: '<%= customOptions.boot_image_family %>'
      assign_external_ip: '<%= customOptions.assign_external_ip %>'
      ssh_username: '<%= customOptions.ssh_username %>'
      ssh_public_key: '<%= customOptions.ssh_public_key %>'
      user_groups: '<%= customOptions.user_groups %>'
      network_name: '<%= customOptions.network_name %>'
      subnetwork_name: '<%= customOptions.subnetwork_name %>'
      allowed_http_cidr: '<%= customOptions.allowed_http_cidr %>'
      allowed_ssh_cidr: '<%= customOptions.allowed_ssh_cidr %>'
      customOptions:
        name: '<%= customOptions.vm_name %>'
        vm_name: '<%= customOptions.vm_name %>'
        app_name: '<%= customOptions.vm_name %>'
      terraform:
        name: '<%= customOptions.vm_name %>'
        vm_name: '<%= customOptions.vm_name %>'
        app_name: '<%= customOptions.vm_name %>'
      templateParameter:
        name: '<%= customOptions.vm_name %>'
        vm_name: '<%= customOptions.vm_name %>'
        app_name: '<%= customOptions.vm_name %>'
      templateParameters:
        name: '<%= customOptions.vm_name %>'
        vm_name: '<%= customOptions.vm_name %>'
        app_name: '<%= customOptions.vm_name %>'
  EOT
  option_type_ids = local.vm_nginx_option_type_ids

  content = <<-EOT
    ### ${var.blueprint_name}

    Provisiona uma instância Compute Engine no Google Cloud Platform (GCP)
    através do engine **Terraform Nativo** do Morpheus Data.

    - **Estado (.tfstate)**: Mantido automaticamente no Cypher do Morpheus.
    - **Formulário**: Preencha os campos com os parâmetros da VM a ser criada.
  EOT
}
