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
  })
}

# Garante que o segredo individual com as credenciais GCP também exista no Cypher
resource "hpe_morpheus_cypher_secret" "gcp_credentials" {
  key = "secret/gcp-terraform-ansible-samples"
  ttl = var.cypher_secret_ttl

  value = var.gcp_credentials != null ? var.gcp_credentials : ""
}
