locals {
  input_parameters = {
    poc_name                         = var.poc_name
    project_id                       = var.project_id
    region                           = var.region
    zone                             = var.zone
    manage_vm_external_ip_org_policy = var.manage_vm_external_ip_org_policy
    ssh_username                     = var.ssh_username
    ssh_public_key                   = var.ssh_public_key
    use_metadata_ssh_keys            = var.use_metadata_ssh_keys
    network_name                     = var.network_name
    subnetwork_name                  = var.subnetwork_name
    allowed_http_cidr                = var.allowed_http_cidr
    allowed_ssh_cidr                 = var.allowed_ssh_cidr
    run_ansible                      = var.run_ansible
    ansible_wait_seconds             = var.ansible_wait_seconds
    ansible_max_retries              = var.ansible_max_retries
    ansible_private_key_file         = var.ansible_private_key_file
    ansible_ssh_user                 = var.ansible_ssh_user
  }

  vm_details = {
    for vm_key, vm in google_compute_instance.vm : vm_key => {
      vm_name                          = vm.name
      zone                             = vm.zone
      machine_type                     = vm.machine_type
      machine_type_override            = local.vm_configs[vm_key].machine_type_override
      machine_series                   = local.vm_configs[vm_key].machine_series
      vcpu_count                       = local.vm_configs[vm_key].vcpu_count
      memory_gb                        = local.vm_configs[vm_key].memory_gb
      memory_mb                        = local.vm_configs[vm_key].memory_mb
      disk_type                        = local.vm_configs[vm_key].disk_type
      disk_size_gb                     = local.vm_configs[vm_key].disk_size_gb
      boot_image_project               = local.vm_configs[vm_key].boot_image_project
      boot_image_family                = local.vm_configs[vm_key].boot_image_family
      assign_external_ip               = local.vm_configs[vm_key].assign_external_ip
      ssh_username                     = local.vm_configs[vm_key].ssh_username
      ssh_public_key                   = local.vm_configs[vm_key].ssh_public_key
      user_groups                      = local.vm_configs[vm_key].user_groups
      network_name                     = local.vm_configs[vm_key].network_name
      subnetwork_name                  = local.vm_configs[vm_key].subnetwork_name
      allowed_http_cidr                = local.vm_configs[vm_key].allowed_http_cidr
      allowed_ssh_cidr                 = local.vm_configs[vm_key].allowed_ssh_cidr
      manage_vm_external_ip_org_policy = local.vm_configs[vm_key].manage_vm_external_ip_org_policy
      metadata_ssh_keys                = local.vm_metadata_ssh_keys[vm_key]
      metadata_ssh_key_entries         = local.vm_metadata_ssh_key_entries[vm_key]
      vm_internal_ip                   = vm.network_interface[0].network_ip
      vm_external_ip                   = try(vm.network_interface[0].access_config[0].nat_ip, null)
      ansible_target_host              = try(vm.network_interface[0].access_config[0].nat_ip, null) != null ? try(vm.network_interface[0].access_config[0].nat_ip, null) : vm.network_interface[0].network_ip
      ssh_access_hint                  = try(vm.network_interface[0].access_config[0].nat_ip, null) != null ? format("ssh -i <caminho-da-chave-privada> %s@%s", local.vm_configs[vm_key].ssh_username, try(vm.network_interface[0].access_config[0].nat_ip, "")) : format("VM sem IP externo. Use VPN, bastion ou IAP para alcançar %s.", vm.network_interface[0].network_ip)
      tags                             = vm.tags
    }
  }

  deployment_summary = {
    input_parameters                           = local.input_parameters
    vm_external_ip_allowed_values              = local.vm_external_ip_allowed_values
    manage_vm_external_ip_org_policy_effective = local.manage_vm_external_ip_org_policy_effective
    vms                                        = local.vm_details
  }

  single_vm_details = length(local.vm_details) == 1 ? local.vm_details[keys(local.vm_details)[0]] : null
}

output "input_parameters" {
  description = "Parâmetros globais informados para a PoC neste módulo Terraform."
  value       = local.input_parameters
}

output "vm_effective_configurations" {
  description = "Mapa consolidado com parâmetros efetivos e atributos gerados para cada VM provisionada."
  value       = local.vm_details
}

output "deployment_summary" {
  description = "Resumo completo da implantação com inputs globais, cálculo efetivo da Org Policy e detalhes das VMs."
  value       = local.deployment_summary
}

output "vm_names" {
  description = "Mapa com os nomes das VMs provisionadas por chave lógica."
  value       = { for vm_key, vm in local.vm_details : vm_key => vm.vm_name }
}

output "vm_internal_ips" {
  description = "Mapa com os IPs internos das VMs por chave lógica."
  value       = { for vm_key, vm in local.vm_details : vm_key => vm.vm_internal_ip }
}

output "vm_external_ips" {
  description = "Mapa com os IPs externos das VMs por chave lógica (nulo quando assign_external_ip = false)."
  value       = { for vm_key, vm in local.vm_details : vm_key => vm.vm_external_ip }
}

output "ansible_target_hosts" {
  description = "Mapa com o host recomendado para Ansible por chave lógica (IP externo se existir; senão IP interno)."
  value       = { for vm_key, vm in local.vm_details : vm_key => vm.ansible_target_host }
}

output "ssh_access_hints" {
  description = "Mapa com comandos de SSH de referência por chave lógica."
  value       = { for vm_key, vm in local.vm_details : vm_key => vm.ssh_access_hint }
}

output "vm_details" {
  description = "Mapa consolidado com nome, IPs e hint de acesso SSH por VM provisionada."
  value       = local.vm_details
}

output "vm_name" {
  description = "Nome da VM provisionada quando houver apenas uma VM; nulo no modo multi-VM."
  value       = local.single_vm_details != null ? local.single_vm_details.vm_name : null
}

output "vm_internal_ip" {
  description = "IP interno da VM quando houver apenas uma VM; nulo no modo multi-VM."
  value       = local.single_vm_details != null ? local.single_vm_details.vm_internal_ip : null
}

output "vm_external_ip" {
  description = "IP externo da VM quando houver apenas uma VM; nulo no modo multi-VM ou quando assign_external_ip = false."
  value       = local.single_vm_details != null ? local.single_vm_details.vm_external_ip : null
}

output "ansible_target_host" {
  description = "Host recomendado para Ansible quando houver apenas uma VM; nulo no modo multi-VM."
  value       = local.single_vm_details != null ? local.single_vm_details.ansible_target_host : null
}

output "ssh_access_hint" {
  description = "Comando de SSH de referência quando houver apenas uma VM; nulo no modo multi-VM."
  value       = local.single_vm_details != null ? local.single_vm_details.ssh_access_hint : null
}
