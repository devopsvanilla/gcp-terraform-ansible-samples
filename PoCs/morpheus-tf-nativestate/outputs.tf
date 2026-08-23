output "catalog_item_id" {
  description = "ID do item de catálogo publicado no Morpheus Data."
  value       = hpe_morpheus_catalog_item_workflow.vm_nginx_add_and_apply.id
}

output "catalog_item_name" {
  description = "Nome do item de catálogo publicado no Morpheus Data."
  value       = hpe_morpheus_catalog_item_workflow.vm_nginx_add_and_apply.name
}

output "workflow_id" {
  description = "ID do Workflow Operacional de adição de VM."
  value       = hpe_morpheus_workflow_operational.vm_nginx_add_and_apply.id
}

output "cypher_tfvars_key" {
  description = "Chave do manifesto de variáveis no Morpheus Cypher."
  value       = hpe_morpheus_cypher_secret.tfvars_manifest.key
}

output "cypher_tfstate_key" {
  description = "Chave do estado Terraform no Morpheus Cypher."
  value       = hpe_morpheus_cypher_secret.tfstate_manifest.key
}
