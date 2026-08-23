# Define as tarefas operacionais de automação no Morpheus Data
resource "hpe_morpheus_task_shell_script" "add_vm_and_apply" {
  name = "add-vm-to-tfvars-and-apply-native"
  code = "add-vm-to-tfvars-and-apply-native"

  source_type   = "repository"
  repository_id = var.repository_id
  script_path   = "PoCs/morpheus-tf-nativestate/templates/add_vm_and_apply_native.sh"
  version_ref   = var.version_ref

  execute_target       = "local"
  local_repository_id  = tostring(var.repository_id)
  local_repository_ref = var.version_ref

  sudo        = false
  retryable   = false
  result_type = "value"
}

resource "hpe_morpheus_task_shell_script" "remove_vm_and_apply" {
  name = "remove-vm-from-tfvars-and-apply-native"
  code = "remove-vm-from-tfvars-and-apply-native"

  source_type   = "repository"
  repository_id = var.repository_id
  script_path   = "PoCs/morpheus-tf-nativestate/templates/remove_vm_and_apply_native.sh"
  version_ref   = var.version_ref

  execute_target       = "local"
  local_repository_id  = tostring(var.repository_id)
  local_repository_ref = var.version_ref

  sudo        = false
  retryable   = false
  result_type = "value"
}
