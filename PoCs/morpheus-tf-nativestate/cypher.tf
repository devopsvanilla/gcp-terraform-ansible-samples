# Cria o segredo principal de tfvars no Cypher do Morpheus.
# Quando o App Blueprint for executado pelo Morpheus, a engine nativa
# injetará este conteúdo de tfvars durante o terraform plan/apply.
resource "hpe_morpheus_cypher_secret" "vm_nginx_tfvars" {
  key = var.cypher_secret_key
  ttl = var.cypher_secret_ttl

  value = <<-EOT
poc_name                         = <%= (customOptions.poc_name != null && customOptions.poc_name != '') ? "\"#{customOptions.poc_name}\"" : "\"vm-nginx-terraform-ansible\"" %>
project_id                       = <%= (customOptions.project_id != null && customOptions.project_id != '') ? "\"#{customOptions.project_id}\"" : (var.project_id != null ? "\"${var.project_id}\"" : "null") %>
region                           = <%= (customOptions.region != null && customOptions.region != '') ? "\"#{customOptions.region}\"" : "\"us-central1\"" %>
zone                             = <%= (customOptions.zone != null && customOptions.zone != '') ? "\"#{customOptions.zone}\"" : "\"us-central1-a\"" %>
manage_vm_external_ip_org_policy = <%= customOptions.manage_vm_external_ip_org_policy != null ? customOptions.manage_vm_external_ip_org_policy : true %>
ssh_username                     = <%= (customOptions.ssh_username != null && customOptions.ssh_username != '') ? "\"#{customOptions.ssh_username}\"" : "\"devops\"" %>
ssh_public_key                   = <%= (customOptions.ssh_public_key != null && customOptions.ssh_public_key != '') ? "\"#{customOptions.ssh_public_key}\"" : "\"\"" %>
network_name                     = <%= (customOptions.network_name != null && customOptions.network_name != '') ? "\"#{customOptions.network_name}\"" : "\"default\"" %>
subnetwork_name                  = <%= (customOptions.subnetwork_name != null && customOptions.subnetwork_name != '') ? "\"#{customOptions.subnetwork_name}\"" : "\"\"" %>
allowed_http_cidr                = <%= (customOptions.allowed_http_cidr != null && customOptions.allowed_http_cidr != '') ? "\"#{customOptions.allowed_http_cidr}\"" : "\"0.0.0.0/0\"" %>
allowed_ssh_cidr                 = <%= (customOptions.allowed_ssh_cidr != null && customOptions.allowed_ssh_cidr != '') ? "\"#{customOptions.allowed_ssh_cidr}\"" : "\"0.0.0.0/0\"" %>
use_metadata_ssh_keys            = <%= customOptions.use_metadata_ssh_keys != null ? customOptions.use_metadata_ssh_keys : true %>
run_ansible                      = <%= customOptions.run_ansible != null ? customOptions.run_ansible : true %>
ansible_wait_seconds             = <%= customOptions.ansible_wait_seconds != null ? customOptions.ansible_wait_seconds : 15 %>
ansible_max_retries              = <%= customOptions.ansible_max_retries != null ? customOptions.ansible_max_retries : 10 %>
ansible_private_key_file         = ${var.ansible_private_key_file != null ? "\"${var.ansible_private_key_file}\"" : (var.ansible_private_key != null ? "\"<%=cypher.read('secret/ansible-private-key')%>\"" : "null")}
ansible_ssh_user                 = <%= (customOptions.ansible_ssh_user != null && customOptions.ansible_ssh_user != '') ? "\"#{customOptions.ansible_ssh_user}\"" : "\"devops\"" %>

vms = {
  "<%= (customOptions.name != null && customOptions.name != '') ? customOptions.name : (customOptions.vm_name != null && customOptions.vm_name != '' ? customOptions.vm_name : "vm-nginx-poc") %>" = {
    vm_name                          = <%= (customOptions.name != null && customOptions.name != '') ? "\"#{customOptions.name}\"" : (customOptions.vm_name != null && customOptions.vm_name != '' ? "\"#{customOptions.vm_name}\"" : "\"vm-nginx-poc\"") %>
    machine_series                   = <%= (customOptions.machine_series != null && customOptions.machine_series != '') ? "\"#{customOptions.machine_series}\"" : "\"e2\"" %>
    machine_type_override            = <%= (customOptions.machine_type_override != null && customOptions.machine_type_override != '') ? "\"#{customOptions.machine_type_override}\"" : "\"e2-micro\"" %>
    vcpu_count                       = <%= customOptions.vcpu_count != null ? customOptions.vcpu_count : 1 %>
    memory_gb                        = <%= customOptions.memory_gb != null ? customOptions.memory_gb : 1 %>
    disk_type                        = <%= (customOptions.disk_type != null && customOptions.disk_type != '') ? "\"#{customOptions.disk_type}\"" : "\"pd-standard\"" %>
    disk_size_gb                     = <%= customOptions.disk_size_gb != null ? customOptions.disk_size_gb : 30 %>
    boot_image_project               = <%= (customOptions.boot_image_project != null && customOptions.boot_image_project != '') ? "\"#{customOptions.boot_image_project}\"" : "\"debian-cloud\"" %>
    boot_image_family                = <%= (customOptions.boot_image_family != null && customOptions.boot_image_family != '') ? "\"#{customOptions.boot_image_family}\"" : "\"debian-12\"" %>
    assign_external_ip               = <%= customOptions.assign_external_ip != null ? customOptions.assign_external_ip : true %>
    ssh_username                     = <%= (customOptions.ssh_username != null && customOptions.ssh_username != '') ? "\"#{customOptions.ssh_username}\"" : "\"devops\"" %>
    ssh_public_key                   = <%= (customOptions.ssh_public_key != null && customOptions.ssh_public_key != '') ? "\"#{customOptions.ssh_public_key}\"" : "\"\"" %>
    user_groups                      = [<%= (customOptions.user_groups != null && customOptions.user_groups != '') ? customOptions.user_groups.split(',').map { |g| "\"#{g.strip}\"" }.join(', ') : '"sudo", "www-data"' %>]
    network_name                     = <%= (customOptions.network_name != null && customOptions.network_name != '') ? "\"#{customOptions.network_name}\"" : "\"default\"" %>
    subnetwork_name                  = <%= (customOptions.subnetwork_name != null && customOptions.subnetwork_name != '') ? "\"#{customOptions.subnetwork_name}\"" : "\"\"" %>
    allowed_http_cidr                = <%= (customOptions.allowed_http_cidr != null && customOptions.allowed_http_cidr != '') ? "\"#{customOptions.allowed_http_cidr}\"" : "\"0.0.0.0/0\"" %>
    allowed_ssh_cidr                 = <%= (customOptions.allowed_ssh_cidr != null && customOptions.allowed_ssh_cidr != '') ? "\"#{customOptions.allowed_ssh_cidr}\"" : "\"0.0.0.0/0\"" %>
    manage_vm_external_ip_org_policy = <%= customOptions.manage_vm_external_ip_org_policy != null ? customOptions.manage_vm_external_ip_org_policy : true %>
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
