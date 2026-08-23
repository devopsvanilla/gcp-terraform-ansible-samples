# Cria o segredo principal de tfvars no Cypher do Morpheus em formato JSON válido.
# O Cypher armazena dados estáticos e credenciais do projeto GCP.
# Os parâmetros dinâmicos do formulário (Option Types) são injetados pelo Morpheus via Item de Catálogo (app_spec).
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

