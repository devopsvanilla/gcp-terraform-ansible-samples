locals {
  input_parameters = {
    poc_name              = var.poc_name
    project_id            = var.project_id
    region                = var.region
    zone                  = var.zone
    ssh_username          = var.ssh_username
    ssh_public_key        = var.ssh_public_key
    use_metadata_ssh_keys = var.use_metadata_ssh_keys
    network_name          = var.network_name
    subnetwork_name       = var.subnetwork_name
    allowed_http_cidr     = var.allowed_http_cidr
    allowed_ssh_cidr      = var.allowed_ssh_cidr
  }

  vm_details = {
    for vm_key, vm in google_compute_instance.vm : vm_key => {
      vm_name               = vm.name
      zone                  = vm.zone
      machine_type          = vm.machine_type
      machine_type_override = local.vm_configs[vm_key].machine_type_override
      machine_series        = local.vm_configs[vm_key].machine_series
      vcpu_count            = local.vm_configs[vm_key].vcpu_count
      memory_gb             = local.vm_configs[vm_key].memory_gb
      memory_mb             = local.vm_configs[vm_key].memory_mb
      disk_type             = local.vm_configs[vm_key].disk_type
      disk_size_gb          = local.vm_configs[vm_key].disk_size_gb
      boot_image_project    = local.vm_configs[vm_key].boot_image_project
      boot_image_family     = local.vm_configs[vm_key].boot_image_family
      assign_external_ip    = local.vm_configs[vm_key].assign_external_ip
      ssh_username          = local.vm_configs[vm_key].ssh_username
      ssh_public_key        = local.vm_configs[vm_key].ssh_public_key
      user_groups           = local.vm_configs[vm_key].user_groups
      network_name          = local.vm_configs[vm_key].network_name
      subnetwork_name       = local.vm_configs[vm_key].subnetwork_name
      allowed_http_cidr     = local.vm_configs[vm_key].allowed_http_cidr
      allowed_ssh_cidr      = local.vm_configs[vm_key].allowed_ssh_cidr
      vm_id                 = vm.instance_id
      self_link             = vm.self_link
      vm_internal_ip        = try(vm.network_interface[0].network_ip, null)
      vm_external_ip        = try(vm.network_interface[0].access_config[0].nat_ip, null)
      effective_ip          = try(vm.network_interface[0].access_config[0].nat_ip, vm.network_interface[0].network_ip, null)
      ssh_access_hint       = format("ssh %s@%s", local.vm_configs[vm_key].ssh_username, coalesce(try(vm.network_interface[0].access_config[0].nat_ip, null), try(vm.network_interface[0].network_ip, null), "IP_NAO_DISPONIVEL"))
    }
  }

  single_vm_key     = length(keys(local.vm_details)) == 1 ? keys(local.vm_details)[0] : null
  single_vm_details = local.single_vm_key != null ? local.vm_details[local.single_vm_key] : null

  deployment_summary = {
    inputs = local.input_parameters
    vms    = local.vm_details
  }
}

output "vm_effective_configurations" {
  description = "Mapa consolidado com parâmetros efetivos e atributos gerados para cada VM provisionada."
  value       = local.vm_details
}

output "deployment_summary" {
  description = "Resumo completo da implantação com inputs globais e detalhes das VMs."
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

output "ssh_access_hint" {
  description = "Comando de SSH de referência quando houver apenas uma VM; nulo no modo multi-VM."
  value       = local.single_vm_details != null ? local.single_vm_details.ssh_access_hint : null
}
