# Gerencia as chaves de variáveis (tfvars) e estado (tfstate) no Cypher do Morpheus Data (Native State).
# O conteúdo destas chaves é mantido dinamicamente sincronizado pelas tasks de criação e remoção de VMs.

resource "hpe_morpheus_cypher_secret" "tfvars_manifest" {
  key = var.cypher_secret_key != null && var.cypher_secret_key != "" ? var.cypher_secret_key : "secret/tfvars-gcp-create-vm-nativestate"
  ttl = var.cypher_secret_ttl

  value = <<-EOF
poc_name              = "${var.poc_name != null && var.poc_name != "" ? var.poc_name : "gcp-create-vm"}"
project_id            = "${var.project_id != "" ? var.project_id : "poc-terraform-ansible"}"
region                = "${var.region != null && var.region != "" ? var.region : "us-central1"}"
zone                  = "${var.zone != null && var.zone != "" ? var.zone : "us-central1-a"}"
use_metadata_ssh_keys = ${var.use_metadata_ssh_keys != null ? tostring(var.use_metadata_ssh_keys) : "true"}
network_name          = "default"
allowed_http_cidr     = "0.0.0.0/0"
allowed_ssh_cidr      = "0.0.0.0/0"

vms = {}
EOF

  lifecycle {
    ignore_changes = [value]
  }
}

# Inicializa o segredo de estado tfstate vazio no Cypher se não existir
resource "hpe_morpheus_cypher_secret" "tfstate_manifest" {
  key = "secret/tfstate-gcp-create-vm-nativestate"
  ttl = 0

  value = "{}"

  lifecycle {
    ignore_changes = [value]
  }
}
