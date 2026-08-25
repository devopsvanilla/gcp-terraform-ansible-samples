# Cria o segredo principal de tfvars no Cypher do Morpheus em formato JSON válido.
resource "hpe_morpheus_cypher_secret" "vm_nginx_tfvars" {
  key = var.cypher_secret_key
  ttl = var.cypher_secret_ttl

  value = <<-EOT
poc_name              = "gcp-create-vm"
project_id            = "${var.project_id}"
gcp_credentials       = ${jsonencode(var.gcp_credentials)}
region                = "${var.region}"
zone                  = "${var.zone}"
use_metadata_ssh_keys = true

name                  = "<%=customOptions.vm_name%>"
vm_name               = "<%=customOptions.vm_name%>"
machine_series        = "<%=customOptions.machine_series%>"
machine_type_override = "<%=customOptions.machine_type_override%>"
vcpu_count            = <%=customOptions.vcpu_count%>
memory_gb             = <%=customOptions.memory_gb%>
disk_type             = "<%=customOptions.disk_type%>"
disk_size_gb          = <%=customOptions.disk_size_gb%>
boot_image_project    = "<%=customOptions.boot_image_project%>"
boot_image_family     = "<%=customOptions.boot_image_family%>"
assign_external_ip    = <%=customOptions.assign_external_ip%>
ssh_username          = "<%=customOptions.ssh_username%>"
ssh_public_key        = <<-EOPK
<%=customOptions.ssh_public_key%>
EOPK
network_name          = "<%=customOptions.network_name%>"
subnetwork_name       = "<%=customOptions.subnetwork_name%>"
allowed_http_cidr     = "<%=customOptions.allowed_http_cidr%>"
allowed_ssh_cidr      = "<%=customOptions.allowed_ssh_cidr%>"
EOT
}

# Garante que o segredo individual com as credenciais GCP também exista no Cypher
resource "hpe_morpheus_cypher_secret" "gcp_credentials" {
  key = "gcp-terraform-ansible-samples"
  ttl = var.cypher_secret_ttl

  value = var.gcp_credentials != null ? var.gcp_credentials : ""
}
