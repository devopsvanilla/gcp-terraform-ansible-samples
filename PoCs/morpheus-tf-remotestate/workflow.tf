locals {
  vm_nginx_option_type_ids = [
    tonumber(hpe_morpheus_option_type_text.vm_name.id),
    tonumber(hpe_morpheus_option_type_text.machine_type_override.id),
    tonumber(hpe_morpheus_option_type_text.machine_series.id),
    tonumber(hpe_morpheus_option_type_number.vcpu_count.id),
    tonumber(hpe_morpheus_option_type_number.memory_gb.id),
    tonumber(hpe_morpheus_option_type_text.disk_type.id),
    tonumber(hpe_morpheus_option_type_number.disk_size_gb.id),
    tonumber(hpe_morpheus_option_type_text.boot_image_project.id),
    tonumber(hpe_morpheus_option_type_text.boot_image_family.id),
    tonumber(hpe_morpheus_option_type_checkbox.assign_external_ip.id),
    tonumber(hpe_morpheus_option_type_text.ssh_username.id),
    tonumber(hpe_morpheus_option_type_text.ssh_public_key.id),
    tonumber(hpe_morpheus_option_type_text.network_name.id),
    tonumber(hpe_morpheus_option_type_text.subnetwork_name.id),
    tonumber(hpe_morpheus_option_type_text.allowed_http_cidr.id),
    tonumber(hpe_morpheus_option_type_text.allowed_ssh_cidr.id),
    tonumber(hpe_morpheus_option_type_checkbox.manage_vm_external_ip_org_policy.id),
    tonumber(hpe_morpheus_option_type_text.user_groups.id),
  ]
}

resource "hpe_morpheus_workflow_operational" "vm_nginx_add_and_apply" {
  name        = var.workflow_name
  description = var.blueprint_description
  visibility  = var.blueprint_visibility

  option_types = local.vm_nginx_option_type_ids
  task_ids     = [tonumber(hpe_morpheus_task_shell_script.add_vm_and_apply.id)]
}

# Provisioning Workflow com fase Teardown (acionado automaticamente ao excluir a VM no Morpheus)
resource "hpe_morpheus_workflow_provisioning" "vm_nginx_provisioning" {
  name        = "vm-nginx-provisioning-workflow"
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
  name        = "vm-nginx-remove-and-apply"
  description = "Remove uma VM do terraform.tfvars e aplica o desprovisionamento no Terraform"
  visibility  = var.blueprint_visibility

  option_types = [
    tonumber(hpe_morpheus_option_type_text.vm_name.id),
  ]
  task_ids = [tonumber(hpe_morpheus_task_shell_script.remove_vm_and_apply.id)]
}

