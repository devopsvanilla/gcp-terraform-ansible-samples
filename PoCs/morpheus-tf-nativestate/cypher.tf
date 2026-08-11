# Gera uma chave privada SSH dedicada para o Ansible via Terraform caso nenhuma seja fornecida.
resource "tls_private_key" "ansible_ssh_key" {
  algorithm = "ED25519"
}

# Armazena a chave privada do Ansible no Cypher do Morpheus sob a chave secret/ansible-private-key.
resource "hpe_morpheus_cypher_secret" "ansible_private_key" {
  key   = "ansible-private-key"
  value = var.ansible_private_key != null ? var.ansible_private_key : tls_private_key.ansible_ssh_key.private_key_openssh
  ttl   = var.cypher_secret_ttl
}

# Cria o segredo principal de tfvars no Cypher do Morpheus em formato JSON válido.
# O Morpheus TerraformService utiliza JsonSlurper para ler o segredo do Cypher e gerar o morpheus-*.tfvars.
resource "hpe_morpheus_cypher_secret" "vm_nginx_tfvars" {
  key = var.cypher_secret_key
  ttl = var.cypher_secret_ttl

  depends_on = [hpe_morpheus_cypher_secret.ansible_private_key]

  value = jsonencode({
    poc_name                         = coalesce(var.poc_name, "vm-nginx-terraform-ansible")
    project_id                       = var.project_id
    gcp_credentials                  = coalesce(var.gcp_credentials, "<%=cypher.read('secret/gcp-terraform-ansible-samples')%>")
    region                           = coalesce(var.region, "us-central1")
    zone                             = coalesce(var.zone, "us-central1-a")
    manage_vm_external_ip_org_policy = coalesce(var.manage_vm_external_ip_org_policy, true)
    ssh_username                     = coalesce(var.ssh_username, "devopsvanilla")
    ssh_public_key                   = coalesce(var.ssh_public_key, "")
    network_name                     = coalesce(var.network_name, "default")
    subnetwork_name                  = coalesce(var.subnetwork_name, "")
    allowed_http_cidr                = coalesce(var.allowed_http_cidr, "0.0.0.0/0")
    allowed_ssh_cidr                 = coalesce(var.allowed_ssh_cidr, "0.0.0.0/0")
    use_metadata_ssh_keys            = coalesce(var.use_metadata_ssh_keys, true)
    run_ansible                      = coalesce(var.run_ansible, true)
    ansible_wait_seconds             = coalesce(var.ansible_wait_seconds, 15)
    ansible_max_retries              = coalesce(var.ansible_max_retries, 3)
    ansible_private_key_file         = coalesce(var.ansible_private_key_file, "<%=cypher.read('secret/ansible-private-key')%>")
    ansible_ssh_user                 = coalesce(var.ansible_ssh_user, "devopsvanilla_ansible")

    vms = {
      (coalesce(var.vm_name, "vm-nginx-poc")) = {
        vm_name                          = coalesce(var.vm_name, "vm-nginx-poc")
        machine_series                   = coalesce(var.machine_series, "e2")
        machine_type_override            = coalesce(var.machine_type_override, "e2-micro")
        vcpu_count                       = coalesce(var.vcpu_count, 1)
        memory_gb                        = coalesce(var.memory_gb, 1)
        disk_type                        = coalesce(var.disk_type, "pd-standard")
        disk_size_gb                     = coalesce(var.disk_size_gb, 30)
        boot_image_project               = coalesce(var.boot_image_project, "debian-cloud")
        boot_image_family                = coalesce(var.boot_image_family, "debian-12")
        assign_external_ip               = coalesce(var.assign_external_ip, true)
        ssh_username                     = coalesce(var.ssh_username, "devopsvanilla")
        ssh_public_key                   = coalesce(var.ssh_public_key, "")
        user_groups                      = [for g in split(",", coalesce(var.user_groups, "sudo, www-data")) : trimspace(g)]
        network_name                     = coalesce(var.network_name, "default")
        subnetwork_name                  = coalesce(var.subnetwork_name, "")
        allowed_http_cidr                = coalesce(var.allowed_http_cidr, "0.0.0.0/0")
        allowed_ssh_cidr                 = coalesce(var.allowed_ssh_cidr, "0.0.0.0/0")
        manage_vm_external_ip_org_policy = coalesce(var.manage_vm_external_ip_org_policy, true)
      }
    }
  })
}
