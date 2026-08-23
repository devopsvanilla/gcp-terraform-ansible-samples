# Cria o App Blueprint Terraform NATIVO no Morpheus Data.
# De acordo com a documentação oficial do Morpheus Data:
# 1. O Morpheus executa o código Terraform a partir do repositório Git vinculado.
# 2. As variáveis de entrada são injetadas a partir do Cypher secret apontado por tfvar_secret.
# 3. O estado (.tfstate) da aplicação é armazenado e mantido nativamente no Cypher do Morpheus.
resource "hpe_morpheus_app_blueprint_terraform" "vm_nginx" {
  name              = var.blueprint_name
  description       = var.blueprint_description
  category          = var.blueprint_category
  source_type       = "repository"
  integration_id    = var.integration_id
  repository_id     = var.repository_id
  version_ref       = var.version_ref
  working_path      = var.working_path
  terraform_version = var.terraform_version
  tfvar_secret      = hpe_morpheus_cypher_secret.vm_nginx_tfvars.key
  terraform_options = "-var 'disk_size_gb=<%= customOptions.disk_size_gb ?: 30 %>' -var 'memory_gb=<%= customOptions.memory_gb ?: 1 %>' -var 'vcpu_count=<%= customOptions.vcpu_count ?: 1 %>' -var 'machine_series=<%= customOptions.machine_series ?: \"e2\" %>' -var 'machine_type_override=<%= customOptions.machine_type_override ?: \"e2-micro\" %>' -var 'disk_type=<%= customOptions.disk_type ?: \"pd-standard\" %>' -var 'boot_image_project=<%= customOptions.boot_image_project ?: \"debian-cloud\" %>' -var 'boot_image_family=<%= customOptions.boot_image_family ?: \"debian-12\" %>' -var 'assign_external_ip=<%= customOptions.assign_external_ip ?: true %>' -var 'ssh_username=<%= customOptions.ssh_username ?: \"devopsvanilla\" %>' -var 'network_name=<%= customOptions.network_name ?: \"default\" %>' -var 'subnetwork_name=<%= customOptions.subnetwork_name ?: \"\" %>' -var 'allowed_http_cidr=<%= customOptions.allowed_http_cidr ?: \"0.0.0.0/0\" %>' -var 'allowed_ssh_cidr=<%= customOptions.allowed_ssh_cidr ?: \"0.0.0.0/0\" %>'"
}
