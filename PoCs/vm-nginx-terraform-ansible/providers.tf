# Credenciais GCP injetadas via ERB do Morpheus Cypher.
# Quando executado pelo Morpheus, a tag ERB é processada ANTES do terraform plan
# e substituída pelo JSON real da chave da Service Account.
# Quando executado localmente (sem Morpheus), a tag ERB permanece como texto literal
# e can(jsondecode()) retorna false, caindo para var.gcp_credentials ou ADC (null).
locals {
  morpheus_gcp_credentials = <<-GCPCRED
  <%=cypher.read('secret/gcp-terraform-ansible-samples')%>
  GCPCRED
}

provider "google" {
  project               = var.project_id
  region                = var.region
  zone                  = var.zone
  billing_project       = var.project_id
  user_project_override = true

  # Precedência:
  #   1. var.gcp_credentials (passada via tfvars ou CLI — uso local)
  #   2. Morpheus Cypher via ERB (quando can(jsondecode) retorna true)
  #   3. ADC / gcloud auth application-default login (fallback)
  credentials = (
    try(trimspace(var.gcp_credentials), "") != ""
    ? var.gcp_credentials
    : can(jsondecode(local.morpheus_gcp_credentials))
    ? trimspace(local.morpheus_gcp_credentials)
    : null
  )
}

