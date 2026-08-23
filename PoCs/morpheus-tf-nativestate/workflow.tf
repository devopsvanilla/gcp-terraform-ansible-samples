resource "hpe_morpheus_workflow_operational" "vm_nginx_add_and_apply" {
  name        = "${var.blueprint_name}-add-and-apply"
  description = var.blueprint_description
  visibility  = var.blueprint_visibility

  option_types = local.vm_nginx_option_type_ids
  task_ids     = [tonumber(hpe_morpheus_task_shell_script.add_vm_and_apply.id)]
}

# Provisioning Workflow com fase Teardown (acionado automaticamente ao excluir a VM no Morpheus)
resource "hpe_morpheus_workflow_provisioning" "vm_nginx_lifecycle" {
  name        = "${var.blueprint_name}-lifecycle"
  description = "Workflow de ciclo de vida com Terraform (Teardown automático na exclusão da VM)"
  visibility  = var.blueprint_visibility
  platform    = "linux"

  task {
    task_id    = tonumber(hpe_morpheus_task_shell_script.remove_vm_and_apply.id)
    task_phase = "teardown"
  }
}

# Operational Workflow de remoção manual/sob demanda via catálogo de serviços
resource "hpe_morpheus_workflow_operational" "vm_nginx_remove_and_apply" {
  name        = "${var.blueprint_name}-remove-and-apply"
  description = "Remove uma VM do terraform.tfvars no Cypher e aplica o desprovisionamento no Terraform"
  visibility  = var.blueprint_visibility

  option_types = [
    tonumber(hpe_morpheus_option_type_text.vm_name.id),
  ]
  task_ids = [tonumber(hpe_morpheus_task_shell_script.remove_vm_and_apply.id)]
}
