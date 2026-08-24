output "blueprint_id" {
  description = "ID do App Blueprint Terraform criado no Morpheus Data."
  value       = hpe_morpheus_app_blueprint_terraform.vm_nginx.id
}

output "blueprint_name" {
  description = "Nome do App Blueprint Terraform criado no Morpheus Data."
  value       = hpe_morpheus_app_blueprint_terraform.vm_nginx.name
}

output "catalog_item_id" {
  description = "ID do Item de Catálogo publicado no Morpheus Data."
  value       = hpe_morpheus_catalog_item_app_blueprint.vm_nginx.id
}

output "catalog_item_name" {
  description = "Nome do Item de Catálogo publicado no Morpheus Data."
  value       = hpe_morpheus_catalog_item_app_blueprint.vm_nginx.name
}


output "cypher_secret_key" {
  description = "Chave do segredo no Cypher utilizada pelo Blueprint."
  value       = hpe_morpheus_cypher_secret.vm_nginx_tfvars.key
}
