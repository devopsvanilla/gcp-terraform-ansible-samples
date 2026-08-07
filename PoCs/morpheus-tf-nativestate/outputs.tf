output "blueprint_id" {
  value       = hpe_morpheus_app_blueprint_terraform.vm_nginx.id
  description = "ID do App Blueprint Terraform nativo criado no Morpheus Data."
}

output "blueprint_name" {
  value       = hpe_morpheus_app_blueprint_terraform.vm_nginx.name
  description = "Nome do App Blueprint no Morpheus Data."
}

output "cypher_secret_key" {
  value       = hpe_morpheus_cypher_secret.vm_nginx_tfvars.key
  description = "Caminho do segredo no Cypher onde os valores padrão do tfvars estão armazenados."
}

output "catalog_item_id" {
  value       = hpe_morpheus_catalog_item_app_blueprint.vm_nginx.id
  description = "ID do item de catálogo publicado para Self-Service no Morpheus Data."
}

output "option_type_ids" {
  value       = local.vm_nginx_option_type_ids
  description = "Lista dos IDs dos Option Types associados ao formulário do App Blueprint."
}
