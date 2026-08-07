output "task_id" {
  description = "ID da shell script task que executa add-vm-to-tfvars.sh e o terraform apply."
  value       = hpe_morpheus_task_shell_script.add_vm_and_apply.id
}

output "workflow_id" {
  description = "ID do workflow operacional que agrupa o formulário (option types) e a task."
  value       = hpe_morpheus_workflow_operational.vm_nginx_add_and_apply.id
}

output "catalog_item_id" {
  description = "ID do item de catálogo (App Blueprint de self-service) publicado no Morpheus Data."
  value       = hpe_morpheus_catalog_item_workflow.vm_nginx_add_and_apply.id
}

output "catalog_item_name" {
  description = "Nome exibido do App Blueprint no catálogo de self-service do Morpheus Data."
  value       = hpe_morpheus_catalog_item_workflow.vm_nginx_add_and_apply.name
}
