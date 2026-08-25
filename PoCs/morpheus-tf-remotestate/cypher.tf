# Gerencia a chave de variáveis tfvars no Cypher do Morpheus Data.
# O conteúdo desta chave é mantido dinamicamente sincronizado pelas tasks de criação e remoção de VMs.

resource "hpe_morpheus_cypher_secret" "tfvars_manifest" {
  key = var.cypher_tfvars_key
  ttl = var.cypher_tfvars_ttl

  value = <<-EOF
poc_name                         = "gcp-create-vm-gcstate"
project_id                       = "${var.project_id != "" ? var.project_id : "poc-terraform-ansible"}"
region                           = "us-central1"
zone                             = "us-central1-a"
manage_vm_external_ip_org_policy = false
network_name                     = "default"
allowed_http_cidr                = "0.0.0.0/0"
allowed_ssh_cidr                 = "0.0.0.0/0"

vms = {}
EOF

  lifecycle {
    ignore_changes = [value]
  }
}

# Garante que o segredo individual com as credenciais GCP também exista no Cypher quando fornecido
resource "hpe_morpheus_cypher_secret" "gcp_credentials" {
  count = var.gcp_credentials != null && var.gcp_credentials != "" ? 1 : 0

  key   = var.cypher_gcp_credentials_key
  ttl   = var.cypher_tfvars_ttl
  value = var.gcp_credentials
}
