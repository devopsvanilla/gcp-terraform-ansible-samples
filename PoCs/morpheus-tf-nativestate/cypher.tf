# Cria o segredo principal de tfvars no Cypher do Morpheus.
# Quando o App Blueprint for executado pelo Morpheus, a engine nativa
# injetará este conteúdo de tfvars durante o terraform plan/apply.
resource "hpe_morpheus_cypher_secret" "vm_nginx_tfvars" {
  key = var.cypher_secret_key
  ttl = var.cypher_secret_ttl

  value = <<-EOT
poc_name                         = ${var.poc_name != null ? "\"${var.poc_name}\"" : "\"vm-nginx-terraform-ansible\""}
project_id                       = ${var.project_id != null ? "\"${var.project_id}\"" : "null"}
gcp_credentials                  = <<-GCP_SA_KEY_EOF
${var.gcp_credentials != null ? var.gcp_credentials : "<%=cypher.read('secret/gcp-terraform-ansible-samples')%>"}
GCP_SA_KEY_EOF
region                           = ${var.region != null ? "\"${var.region}\"" : "\"us-central1\""}
zone                             = ${var.zone != null ? "\"${var.zone}\"" : "\"us-central1-a\""}
manage_vm_external_ip_org_policy = ${var.manage_vm_external_ip_org_policy != null ? tostring(var.manage_vm_external_ip_org_policy) : "true"}
ssh_username                     = ${var.ssh_username != null ? "\"${var.ssh_username}\"" : "\"devopsvanilla\""}
ssh_public_key                   = ${var.ssh_public_key != null ? "\"${var.ssh_public_key}\"" : "\"\""}
network_name                     = ${var.network_name != null ? "\"${var.network_name}\"" : "\"default\""}
subnetwork_name                  = ${var.subnetwork_name != null ? "\"${var.subnetwork_name}\"" : "\"\""}
allowed_http_cidr                = ${var.allowed_http_cidr != null ? "\"${var.allowed_http_cidr}\"" : "\"0.0.0.0/0\""}
allowed_ssh_cidr                 = ${var.allowed_ssh_cidr != null ? "\"${var.allowed_ssh_cidr}\"" : "\"0.0.0.0/0\""}
use_metadata_ssh_keys            = ${var.use_metadata_ssh_keys != null ? tostring(var.use_metadata_ssh_keys) : "true"}
run_ansible                      = ${var.run_ansible != null ? tostring(var.run_ansible) : "true"}
ansible_wait_seconds             = ${var.ansible_wait_seconds != null ? tostring(var.ansible_wait_seconds) : "15"}
ansible_max_retries              = ${var.ansible_max_retries != null ? tostring(var.ansible_max_retries) : "3"}
ansible_private_key_file         = ${var.ansible_private_key_file != null ? "\"${var.ansible_private_key_file}\"" : (var.ansible_private_key != null ? "\"<%=cypher.read('secret/ansible-private-key')%>\"" : "null")}
ansible_ssh_user                 = ${var.ansible_ssh_user != null ? "\"${var.ansible_ssh_user}\"" : "\"devopsvanilla_ansible\""}

vms = {
  "${var.vm_name != null ? var.vm_name : "vm-nginx-poc"}" = {
    vm_name                          = ${var.vm_name != null ? "\"${var.vm_name}\"" : "\"vm-nginx-poc\""}
    machine_series                   = ${var.machine_series != null ? "\"${var.machine_series}\"" : "\"e2\""}
    machine_type_override            = ${var.machine_type_override != null ? "\"${var.machine_type_override}\"" : "\"e2-micro\""}
    vcpu_count                       = ${var.vcpu_count != null ? tostring(var.vcpu_count) : "1"}
    memory_gb                        = ${var.memory_gb != null ? tostring(var.memory_gb) : "1"}
    disk_type                        = ${var.disk_type != null ? "\"${var.disk_type}\"" : "\"pd-standard\""}
    disk_size_gb                     = ${var.disk_size_gb != null ? tostring(var.disk_size_gb) : "30"}
    boot_image_project               = ${var.boot_image_project != null ? "\"${var.boot_image_project}\"" : "\"debian-cloud\""}
    boot_image_family                = ${var.boot_image_family != null ? "\"${var.boot_image_family}\"" : "\"debian-12\""}
    assign_external_ip               = ${var.assign_external_ip != null ? tostring(var.assign_external_ip) : "true"}
    ssh_username                     = ${var.ssh_username != null ? "\"${var.ssh_username}\"" : "\"devopsvanilla\""}
    ssh_public_key                   = ${var.ssh_public_key != null ? "\"${var.ssh_public_key}\"" : "\"\""}
    user_groups                      = [${var.user_groups != null ? join(", ", [for g in split(",", var.user_groups) : "\"${trimspace(g)}\""]) : "\"sudo\", \"www-data\""}]
    network_name                     = ${var.network_name != null ? "\"${var.network_name}\"" : "\"default\""}
    subnetwork_name                  = ${var.subnetwork_name != null ? "\"${var.subnetwork_name}\"" : "\"\""}
    allowed_http_cidr                = ${var.allowed_http_cidr != null ? "\"${var.allowed_http_cidr}\"" : "\"0.0.0.0/0\""}
    allowed_ssh_cidr                 = ${var.allowed_ssh_cidr != null ? "\"${var.allowed_ssh_cidr}\"" : "\"0.0.0.0/0\""}
    manage_vm_external_ip_org_policy = ${var.manage_vm_external_ip_org_policy != null ? tostring(var.manage_vm_external_ip_org_policy) : "true"}
  }
}
  EOT
}

# Se a chave privada do Ansible for fornecida na automação, cria um segredo dedicado
# no Cypher do Morpheus em secret/ansible-private-key para recuperação segura.
resource "hpe_morpheus_cypher_secret" "ansible_private_key" {
  count = var.ansible_private_key != null ? 1 : 0

  key   = "secret/ansible-private-key"
  value = var.ansible_private_key
  ttl   = var.cypher_secret_ttl
}
