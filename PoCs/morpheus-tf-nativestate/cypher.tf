# Cria o segredo principal de tfvars no Cypher do Morpheus em formato JSON válido.
resource "hpe_morpheus_cypher_secret" "vm_nginx_tfvars" {
  key = var.cypher_secret_key
  ttl = var.cypher_secret_ttl

  value = jsonencode({
    poc_name              = var.poc_name != null && var.poc_name != "" ? var.poc_name : "gcp-create-vm"
    project_id            = var.project_id
    gcp_credentials       = var.gcp_credentials != null ? var.gcp_credentials : ""
    region                = var.region != null && var.region != "" ? var.region : "us-central1"
    zone                  = var.zone != null && var.zone != "" ? var.zone : "us-central1-a"
    use_metadata_ssh_keys = var.use_metadata_ssh_keys != null ? var.use_metadata_ssh_keys : true

    vm_name               = "<%=customOptions.vm_name%>"
    machine_series        = "<%=customOptions.machine_series%>"
    machine_type_override = "<%=customOptions.machine_type_override%>"
    vcpu_count            = "<%=customOptions.vcpu_count%>"
    memory_gb             = "<%=customOptions.memory_gb%>"
    disk_type             = "<%=customOptions.disk_type%>"
    disk_size_gb          = "<%=customOptions.disk_size_gb%>"
    boot_image_project    = "<%=customOptions.boot_image_project%>"
    boot_image_family     = "<%=customOptions.boot_image_family%>"
    assign_external_ip    = "<%=customOptions.assign_external_ip%>"
    ssh_username          = "<%=customOptions.ssh_username%>"
    ssh_public_key        = "<%=customOptions.ssh_public_key%>"
    network_name          = "<%=customOptions.network_name%>"
    subnetwork_name       = "<%=customOptions.subnetwork_name%>"
    allowed_http_cidr     = "<%=customOptions.allowed_http_cidr%>"
    allowed_ssh_cidr      = "<%=customOptions.allowed_ssh_cidr%>"
  })
}

# Garante que o segredo individual com as credenciais GCP também exista no Cypher
resource "hpe_morpheus_cypher_secret" "gcp_credentials" {
  key = "secret/gcp-terraform-ansible-samples"
  ttl = var.cypher_secret_ttl

  value = var.gcp_credentials != null ? var.gcp_credentials : ""
}
