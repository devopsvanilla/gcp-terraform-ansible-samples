resource "hpe_morpheus_task_shell_script" "add_vm_and_apply" {
  name = "add-vm-to-tfvars-and-apply"
  code = "add-vm-to-tfvars-and-apply"

  source_type = "local"
  script_content = templatefile("${path.module}/templates/add_vm_and_apply.sh.tftpl", {
    repo_path                   = var.repo_path
    poc_relative_path           = var.poc_relative_path
    add_vm_script_relative_path = var.add_vm_script_relative_path
    terraform_binary            = var.terraform_binary
  })

  execute_target = var.task_execute_target
  sudo           = false
  retryable      = false
  result_type    = "value"

  remote_target_host     = var.task_execute_target == "remote" ? var.remote_target_host : null
  remote_target_port     = var.task_execute_target == "remote" ? var.remote_target_port : null
  remote_target_username = var.task_execute_target == "remote" ? var.remote_target_username : null
  remote_target_password = var.task_execute_target == "remote" ? var.remote_target_password : null
}
