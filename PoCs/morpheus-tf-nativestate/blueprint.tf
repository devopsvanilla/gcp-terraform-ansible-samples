# App Blueprint Nativo do Morpheus Data (tipo Spec Template HCL)
# Permite visualização completa do .tfstate, recursos e detecção de drift no painel Provisioning > Apps.
resource "hpe_morpheus_app_blueprint_terraform" "vm_nginx" {
  name              = var.blueprint_name
  description       = var.blueprint_description
  category          = var.blueprint_category
  source_type       = "spec"
  spec_template_ids = [tonumber(hpe_morpheus_spec_template_terraform.gcp_vm.id)]
  tfvar_secret      = hpe_morpheus_cypher_secret.vm_nginx_tfvars.key
}
