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

output "remove_task_id" {
  description = "ID da task que executa remove-vm-from-tfvars.sh e terraform apply."
  value       = hpe_morpheus_task_shell_script.remove_vm_and_apply.id
}

output "provisioning_workflow_id" {
  description = "ID do provisioning workflow com fase Teardown configurada."
  value       = hpe_morpheus_workflow_provisioning.vm_nginx_provisioning.id
}

output "remove_catalog_item_id" {
  description = "ID do item de catálogo para remoção de VM sob demanda."
  value       = hpe_morpheus_catalog_item_workflow.vm_nginx_remove_and_apply.id
}

output "cypher_tfvars_secret_id" {
  description = "ID do segredo Cypher onde o manifesto terraform.tfvars é armazenado."
  value       = hpe_morpheus_cypher_secret.tfvars_manifest.id
}

output "cypher_gcp_credentials_secret_id" {
  description = "ID do segredo Cypher onde as credenciais GCP são armazenadas."
  value       = try(hpe_morpheus_cypher_secret.gcp_credentials[0].id, null)
}


