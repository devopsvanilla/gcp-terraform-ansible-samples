data "hpe_morpheus_integration_git" "this" {
  count = var.git_integration_name != "" ? 1 : 0
  name  = var.git_integration_name
}

locals {
  # Determina o ID numérico do repositório Git no Morpheus.
  # Pode ser informado diretamente via var.task_repository_id ou consultado via data source.
  repository_id = var.task_repository_id != null ? var.task_repository_id : (
    var.git_integration_name != "" && var.git_repository_name != "" && length(data.hpe_morpheus_integration_git.this) > 0 ? lookup(data.hpe_morpheus_integration_git.this[0].repository_ids, var.git_repository_name, null) : null
  )

  # ID do repositório local para contexto de execução no Morpheus (quando execute_target = "local").
  local_repository_id = var.task_local_repository_id != null ? var.task_local_repository_id : (
    local.repository_id != null ? tostring(local.repository_id) : null
  )
}

resource "hpe_morpheus_task_shell_script" "add_vm_and_apply" {
  name = "add-vm-to-tfvars-and-apply"
  code = "add-vm-to-tfvars-and-apply"

  source_type   = var.task_source_type
  repository_id = var.task_source_type == "repository" ? local.repository_id : null
  script_path   = var.task_source_type == "repository" ? var.task_script_path : null
  version_ref   = var.task_source_type == "repository" ? var.task_version_ref : null

  execute_target       = var.task_execute_target
  local_repository_id  = var.task_execute_target == "local" ? local.local_repository_id : null
  local_repository_ref = var.task_execute_target == "local" ? var.task_local_repository_ref : null

  sudo        = false
  retryable   = false
  result_type = "value"

  remote_target_host     = var.task_execute_target == "remote" ? var.remote_target_host : null
  remote_target_port     = var.task_execute_target == "remote" ? var.remote_target_port : null
  remote_target_username = var.task_execute_target == "remote" ? var.remote_target_username : null
  remote_target_password = var.task_execute_target == "remote" ? var.remote_target_password : null
}

resource "hpe_morpheus_task_shell_script" "remove_vm_and_apply" {
  name = "remove-vm-from-tfvars-and-apply"
  code = "remove-vm-from-tfvars-and-apply"

  source_type   = var.task_source_type
  repository_id = var.task_source_type == "repository" ? local.repository_id : null
  script_path   = var.task_source_type == "repository" ? var.remove_task_script_path : null
  version_ref   = var.task_source_type == "repository" ? var.task_version_ref : null

  execute_target       = var.task_execute_target
  local_repository_id  = var.task_execute_target == "local" ? local.local_repository_id : null
  local_repository_ref = var.task_execute_target == "local" ? var.task_local_repository_ref : null

  sudo        = false
  retryable   = false
  result_type = "value"

  remote_target_host     = var.task_execute_target == "remote" ? var.remote_target_host : null
  remote_target_port     = var.task_execute_target == "remote" ? var.remote_target_port : null
  remote_target_username = var.task_execute_target == "remote" ? var.remote_target_username : null
  remote_target_password = var.task_execute_target == "remote" ? var.remote_target_password : null
}

