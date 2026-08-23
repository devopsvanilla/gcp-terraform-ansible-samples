# Cria o segredo principal de tfvars no Cypher do Morpheus em formato JSON válido.
resource "hpe_morpheus_cypher_secret" "vm_nginx_tfvars" {
  key = var.cypher_secret_key
  ttl = var.cypher_secret_ttl

  value = jsonencode({
    poc_name              = var.poc_name != null && var.poc_name != "" ? var.poc_name : "gcp-create-vm"
    project_id            = var.project_id
    gcp_credentials       = var.gcp_credentials != null && var.gcp_credentials != "" ? var.gcp_credentials : "<%=cypher.read('secret/gcp-terraform-ansible-samples')%>"
    region                = var.region != null && var.region != "" ? var.region : "us-central1"
    zone                  = var.zone != null && var.zone != "" ? var.zone : "us-central1-a"
    ssh_username          = var.ssh_username != null && var.ssh_username != "" ? var.ssh_username : "devopsvanilla"
    ssh_public_key        = var.ssh_public_key != null ? var.ssh_public_key : ""
    network_name          = var.network_name != null && var.network_name != "" ? var.network_name : "default"
    subnetwork_name       = var.subnetwork_name != null ? var.subnetwork_name : ""
    allowed_http_cidr     = var.allowed_http_cidr != null && var.allowed_http_cidr != "" ? var.allowed_http_cidr : "0.0.0.0/0"
    allowed_ssh_cidr      = var.allowed_ssh_cidr != null && var.allowed_ssh_cidr != "" ? var.allowed_ssh_cidr : "0.0.0.0/0"
    use_metadata_ssh_keys = var.use_metadata_ssh_keys != null ? var.use_metadata_ssh_keys : true

    name                  = "<%= app?.name ?: 'vm-gcp-poc' %>"
    vm_name               = "<%= app?.name ?: 'vm-gcp-poc' %>"
    machine_series        = "<%= customOptions.machine_series ?: 'e2' %>"
    machine_type_override = "<%= customOptions.machine_type_override ?: '' %>"
    vcpu_count            = "<%= customOptions.vcpu_count ?: 1 %>"
    memory_gb             = "<%= customOptions.memory_gb ?: 1 %>"
    disk_type             = "<%= customOptions.disk_type ?: 'pd-standard' %>"
    disk_size_gb          = "<%= customOptions.disk_size_gb ?: 30 %>"
    boot_image_project    = "<%= customOptions.boot_image_project ?: 'debian-cloud' %>"
    boot_image_family     = "<%= customOptions.boot_image_family ?: 'debian-12' %>"
    assign_external_ip    = "<%= (customOptions.assign_external_ip.to_s == 'true' || customOptions.assign_external_ip.to_s == 'on') ? 'true' : 'false' %>"
    ssh_username          = "<%= customOptions.ssh_username ?: 'devopsvanilla' %>"
    ssh_public_key        = "<%= customOptions.ssh_public_key ?: '' %>"
    user_groups           = "<%= customOptions.user_groups ?: 'sudo' %>"
    network_name          = "<%= customOptions.network_name ?: 'default' %>"
    subnetwork_name       = "<%= customOptions.subnetwork_name ?: '' %>"
    allowed_http_cidr     = "<%= customOptions.allowed_http_cidr ?: '0.0.0.0/0' %>"
    allowed_ssh_cidr      = "<%= customOptions.allowed_ssh_cidr ?: '0.0.0.0/0' %>"
  })
}
