locals {
  vm_nginx_option_type_ids = [
    tonumber(hpe_morpheus_option_type_text.vm_key.id),
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
