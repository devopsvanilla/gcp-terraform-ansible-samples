# Spec Template Terraform que renderiza dinamicamente as variáveis do formulário (customOptions)
# no momento em que a aplicação é provisionada via Catálogo / App Blueprint.
resource "hpe_morpheus_spec_template_terraform" "vm_vars" {
  name         = "morpheus_inputs.auto.tfvars"
  source_type  = "local"
  spec_content = <<-EOT
disk_size_gb          = <%= (customOptions.disk_size_gb != null && customOptions.disk_size_gb != "") ? customOptions.disk_size_gb : 30 %>
memory_gb             = <%= (customOptions.memory_gb != null && customOptions.memory_gb != "") ? customOptions.memory_gb : 1 %>
vcpu_count            = <%= (customOptions.vcpu_count != null && customOptions.vcpu_count != "") ? customOptions.vcpu_count : 1 %>
machine_series        = "<%= (customOptions.machine_series != null && customOptions.machine_series != "") ? customOptions.machine_series : "e2" %>"
machine_type_override = "<%= (customOptions.machine_type_override != null && customOptions.machine_type_override != "") ? customOptions.machine_type_override : "e2-micro" %>"
disk_type             = "<%= (customOptions.disk_type != null && customOptions.disk_type != "") ? customOptions.disk_type : "pd-standard" %>"
boot_image_project    = "<%= (customOptions.boot_image_project != null && customOptions.boot_image_project != "") ? customOptions.boot_image_project : "debian-cloud" %>"
boot_image_family     = "<%= (customOptions.boot_image_family != null && customOptions.boot_image_family != "") ? customOptions.boot_image_family : "debian-12" %>"
assign_external_ip    = <%= (customOptions.assign_external_ip != null && customOptions.assign_external_ip != "") ? customOptions.assign_external_ip : true %>
ssh_username          = "<%= (customOptions.ssh_username != null && customOptions.ssh_username != "") ? customOptions.ssh_username : "devopsvanilla" %>"
network_name          = "<%= (customOptions.network_name != null && customOptions.network_name != "") ? customOptions.network_name : "default" %>"
subnetwork_name       = "<%= (customOptions.subnetwork_name != null && customOptions.subnetwork_name != "") ? customOptions.subnetwork_name : "" %>"
allowed_http_cidr     = "<%= (customOptions.allowed_http_cidr != null && customOptions.allowed_http_cidr != "") ? customOptions.allowed_http_cidr : "0.0.0.0/0" %>"
allowed_ssh_cidr      = "<%= (customOptions.allowed_ssh_cidr != null && customOptions.allowed_ssh_cidr != "") ? customOptions.allowed_ssh_cidr : "0.0.0.0/0" %>"
EOT
}
