#!/usr/bin/env bash
# Shell Script executado pelo Morpheus Data a partir do repositório Git.
# Os valores entre <%= customOptions[...] %> são substituídos pelo Morpheus Data
# em tempo de execução, com base no formulário preenchido pelo solicitante.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
if [[ -z "${REPO_DIR:-}" ]]; then
  if [[ -d "$SCRIPT_DIR/PoCs/vm-nginx-terraform-ansible" ]]; then
    REPO_DIR="$SCRIPT_DIR"
  elif [[ -d "$SCRIPT_DIR/../../PoCs/vm-nginx-terraform-ansible" ]]; then
    REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
  elif [[ -d "$SCRIPT_DIR/../../../PoCs/vm-nginx-terraform-ansible" ]]; then
    REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  elif [[ -d "$PWD/PoCs/vm-nginx-terraform-ansible" ]]; then
    REPO_DIR="$PWD"
  else
    REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  fi
fi
POC_DIR="${POC_DIR:-$REPO_DIR/PoCs/vm-nginx-terraform-ansible}"
ADD_VM_SCRIPT="${ADD_VM_SCRIPT:-$REPO_DIR/scripts/add-vm-to-tfvars.sh}"
TFVARS_FILE="$POC_DIR/terraform.tfvars"
TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"
TFSTATE_BUCKET="${TFSTATE_BUCKET:-tfstate-devopsvanilla-samples}"
TFSTATE_PREFIX="${TFSTATE_PREFIX:-vm-nginx-terraform-ansible}"

log_info() { printf '[INFO] %s\n' "$*"; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }

clean_opt() {
  local val="$1"
  if [[ "$val" == "null" || "$val" =~ ^<%.*%>$ ]]; then
    echo ""
  else
    echo "$val"
  fi
}

VM_KEY="$(clean_opt '<%= customOptions?.vmKey ?: customOptions?.["vmKey"] ?: customOptions?.["vm_key"] ?: customOptions?.["vm-nginx-vm-key"] ?: "" %>')"
VM_KEY="${VM_KEY:-${MORPHEUS_CUSTOM_OPTIONS_VMKEY:-${MORPHEUS_CUSTOM_OPTIONS_VM_KEY:-${vmKey:-${vm_key:-}}}}}"

VM_NAME="$(clean_opt '<%= customOptions?.vmName ?: customOptions?.["vmName"] ?: customOptions?.["vm_name"] ?: customOptions?.["vm-nginx-vm-name"] ?: "" %>')"
VM_NAME="${VM_NAME:-${MORPHEUS_CUSTOM_OPTIONS_VMNAME:-${MORPHEUS_CUSTOM_OPTIONS_VM_NAME:-${vmName:-${vm_name:-}}}}}"

# Auto-deriva vmKey a partir de vmName se apenas vmName foi preenchido
if [[ -z "$VM_KEY" && -n "$VM_NAME" ]]; then
  VM_KEY="$(echo "$VM_NAME" | tr '-' '_' | tr -cd 'a-zA-Z0-9_')"
  log_info "vmKey preenchido automaticamente a partir de vmName: $VM_KEY"
fi

# Auto-deriva vmName a partir de vmKey se apenas vmKey foi preenchido
if [[ -z "$VM_NAME" && -n "$VM_KEY" ]]; then
  VM_NAME="$(echo "$VM_KEY" | tr '_' '-')"
  log_info "vmName preenchido automaticamente a partir de vmKey: $VM_NAME"
fi

MACHINE_TYPE_OVERRIDE="$(clean_opt '<%= customOptions?.machineTypeOverride ?: customOptions?.["machineTypeOverride"] ?: customOptions?.["machine_type_override"] ?: customOptions?.["vm-nginx-machine-type-override"] ?: "" %>')"
MACHINE_TYPE_OVERRIDE="${MACHINE_TYPE_OVERRIDE:-${MORPHEUS_CUSTOM_OPTIONS_MACHINETYPEOVERRIDE:-${MORPHEUS_CUSTOM_OPTIONS_MACHINE_TYPE_OVERRIDE:-${machineTypeOverride:-${machine_type_override:-}}}}}"

MACHINE_SERIES="$(clean_opt '<%= customOptions?.machineSeries ?: customOptions?.["machineSeries"] ?: customOptions?.["machine_series"] ?: customOptions?.["vm-nginx-machine-series"] ?: "" %>')"
MACHINE_SERIES="${MACHINE_SERIES:-${MORPHEUS_CUSTOM_OPTIONS_MACHINESERIES:-${MORPHEUS_CUSTOM_OPTIONS_MACHINE_SERIES:-${machineSeries:-${machine_series:-}}}}}"

VCPU_COUNT="$(clean_opt '<%= customOptions?.vcpuCount ?: customOptions?.["vcpuCount"] ?: customOptions?.["vcpu_count"] ?: customOptions?.["vm-nginx-vcpu-count"] ?: "" %>')"
VCPU_COUNT="${VCPU_COUNT:-${MORPHEUS_CUSTOM_OPTIONS_VCPUCOUNT:-${MORPHEUS_CUSTOM_OPTIONS_VCPU_COUNT:-${vcpuCount:-${vcpu_count:-}}}}}"

MEMORY_GB="$(clean_opt '<%= customOptions?.memoryGb ?: customOptions?.["memoryGb"] ?: customOptions?.["memory_gb"] ?: customOptions?.["vm-nginx-memory-gb"] ?: "" %>')"
MEMORY_GB="${MEMORY_GB:-${MORPHEUS_CUSTOM_OPTIONS_MEMORYGB:-${MORPHEUS_CUSTOM_OPTIONS_MEMORY_GB:-${memoryGb:-${memory_gb:-}}}}}"

DISK_TYPE="$(clean_opt '<%= customOptions?.diskType ?: customOptions?.["diskType"] ?: customOptions?.["disk_type"] ?: customOptions?.["vm-nginx-disk-type"] ?: "" %>')"
DISK_TYPE="${DISK_TYPE:-${MORPHEUS_CUSTOM_OPTIONS_DISKTYPE:-${MORPHEUS_CUSTOM_OPTIONS_DISK_TYPE:-${diskType:-${disk_type:-}}}}}"

DISK_SIZE_GB="$(clean_opt '<%= customOptions?.diskSizeGb ?: customOptions?.["diskSizeGb"] ?: customOptions?.["disk_size_gb"] ?: customOptions?.["vm-nginx-disk-size-gb"] ?: "" %>')"
DISK_SIZE_GB="${DISK_SIZE_GB:-${MORPHEUS_CUSTOM_OPTIONS_DISKSIZEGB:-${MORPHEUS_CUSTOM_OPTIONS_DISK_SIZE_GB:-${diskSizeGb:-${disk_size_gb:-}}}}}"

BOOT_IMAGE_PROJECT="$(clean_opt '<%= customOptions?.bootImageProject ?: customOptions?.["bootImageProject"] ?: customOptions?.["boot_image_project"] ?: customOptions?.["vm-nginx-boot-image-project"] ?: "" %>')"
BOOT_IMAGE_PROJECT="${BOOT_IMAGE_PROJECT:-${MORPHEUS_CUSTOM_OPTIONS_BOOTIMAGEPROJECT:-${MORPHEUS_CUSTOM_OPTIONS_BOOT_IMAGE_PROJECT:-${bootImageProject:-${boot_image_project:-}}}}}"

BOOT_IMAGE_FAMILY="$(clean_opt '<%= customOptions?.bootImageFamily ?: customOptions?.["bootImageFamily"] ?: customOptions?.["boot_image_family"] ?: customOptions?.["vm-nginx-boot-image-family"] ?: "" %>')"
BOOT_IMAGE_FAMILY="${BOOT_IMAGE_FAMILY:-${MORPHEUS_CUSTOM_OPTIONS_BOOTIMAGEFAMILY:-${MORPHEUS_CUSTOM_OPTIONS_BOOT_IMAGE_FAMILY:-${bootImageFamily:-${boot_image_family:-}}}}}"

ASSIGN_EXTERNAL_IP="$(clean_opt '<%= customOptions?.assignExternalIp ?: customOptions?.["assignExternalIp"] ?: customOptions?.["assign_external_ip"] ?: customOptions?.["vm-nginx-assign-external-ip"] ?: "" %>')"
ASSIGN_EXTERNAL_IP="${ASSIGN_EXTERNAL_IP:-${MORPHEUS_CUSTOM_OPTIONS_ASSIGNEXTERNALIP:-${MORPHEUS_CUSTOM_OPTIONS_ASSIGN_EXTERNAL_IP:-${assignExternalIp:-${assign_external_ip:-}}}}}"

SSH_USERNAME="$(clean_opt '<%= customOptions?.sshUsername ?: customOptions?.["sshUsername"] ?: customOptions?.["ssh_username"] ?: customOptions?.["vm-nginx-ssh-username"] ?: "" %>')"
SSH_USERNAME="${SSH_USERNAME:-${MORPHEUS_CUSTOM_OPTIONS_SSHUSERNAME:-${MORPHEUS_CUSTOM_OPTIONS_SSH_USERNAME:-${sshUsername:-${ssh_username:-}}}}}"

SSH_PUBLIC_KEY="$(clean_opt '<%= customOptions?.sshPublicKey ?: customOptions?.["sshPublicKey"] ?: customOptions?.["ssh_public_key"] ?: customOptions?.["vm-nginx-ssh-public-key"] ?: "" %>')"
SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY:-${MORPHEUS_CUSTOM_OPTIONS_SSHPUBLICKEY:-${MORPHEUS_CUSTOM_OPTIONS_SSH_PUBLIC_KEY:-${sshPublicKey:-${ssh_public_key:-}}}}}"

NETWORK_NAME="$(clean_opt '<%= customOptions?.networkName ?: customOptions?.["networkName"] ?: customOptions?.["network_name"] ?: customOptions?.["vm-nginx-network-name"] ?: "" %>')"
NETWORK_NAME="${NETWORK_NAME:-${MORPHEUS_CUSTOM_OPTIONS_NETWORKNAME:-${MORPHEUS_CUSTOM_OPTIONS_NETWORK_NAME:-${networkName:-${network_name:-}}}}}"

SUBNETWORK_NAME="$(clean_opt '<%= customOptions?.subnetworkName ?: customOptions?.["subnetworkName"] ?: customOptions?.["subnetwork_name"] ?: customOptions?.["vm-nginx-subnetwork-name"] ?: "" %>')"
SUBNETWORK_NAME="${SUBNETWORK_NAME:-${MORPHEUS_CUSTOM_OPTIONS_SUBNETWORKNAME:-${MORPHEUS_CUSTOM_OPTIONS_SUBNETWORK_NAME:-${subnetworkName:-${subnetwork_name:-}}}}}"

ALLOWED_HTTP_CIDR="$(clean_opt '<%= customOptions?.allowedHttpCidr ?: customOptions?.["allowedHttpCidr"] ?: customOptions?.["allowed_http_cidr"] ?: customOptions?.["vm-nginx-allowed-http-cidr"] ?: "" %>')"
ALLOWED_HTTP_CIDR="${ALLOWED_HTTP_CIDR:-${MORPHEUS_CUSTOM_OPTIONS_ALLOWEDHTTPCIDR:-${MORPHEUS_CUSTOM_OPTIONS_ALLOWED_HTTP_CIDR:-${allowedHttpCidr:-${allowed_http_cidr:-}}}}}"

ALLOWED_SSH_CIDR="$(clean_opt '<%= customOptions?.allowedSshCidr ?: customOptions?.["allowedSshCidr"] ?: customOptions?.["allowed_ssh_cidr"] ?: customOptions?.["vm-nginx-allowed-ssh-cidr"] ?: "" %>')"
ALLOWED_SSH_CIDR="${ALLOWED_SSH_CIDR:-${MORPHEUS_CUSTOM_OPTIONS_ALLOWEDSSHCIDR:-${MORPHEUS_CUSTOM_OPTIONS_ALLOWED_SSH_CIDR:-${allowedSshCidr:-${allowed_ssh_cidr:-}}}}}"

MANAGE_ORG_POLICY="$(clean_opt '<%= customOptions?.manageVmExternalIpOrgPolicy ?: customOptions?.["manageVmExternalIpOrgPolicy"] ?: customOptions?.["manage_vm_external_ip_org_policy"] ?: customOptions?.["vm-nginx-manage-org-policy"] ?: "" %>')"
MANAGE_ORG_POLICY="${MANAGE_ORG_POLICY:-${MORPHEUS_CUSTOM_OPTIONS_MANAGEVMEXTERNALIPORGPOLICY:-${MORPHEUS_CUSTOM_OPTIONS_MANAGE_VM_EXTERNAL_IP_ORG_POLICY:-${manageVmExternalIpOrgPolicy:-${manage_vm_external_ip_org_policy:-}}}}}"

USER_GROUPS="$(clean_opt '<%= customOptions?.userGroups ?: customOptions?.["userGroups"] ?: customOptions?.["user_groups"] ?: customOptions?.["vm-nginx-user-groups"] ?: "" %>')"
USER_GROUPS="${USER_GROUPS:-${MORPHEUS_CUSTOM_OPTIONS_USERGROUPS:-${MORPHEUS_CUSTOM_OPTIONS_USER_GROUPS:-${userGroups:-${user_groups:-}}}}}"

if [[ -z "$VM_KEY" || -z "$VM_NAME" ]]; then
  log_error "Parâmetros obrigatórios ausentes. VM_KEY='$VM_KEY', VM_NAME='$VM_NAME'."
  log_error "Certifique-se de preencher o formulário no Catálogo de Serviços do Morpheus antes de executar."
  exit 1
fi

[[ -d "$REPO_DIR" ]] || { log_error "Repositório não encontrado em $REPO_DIR"; exit 1; }
[[ -x "$ADD_VM_SCRIPT" ]] || { log_error "Script não encontrado ou não executável: $ADD_VM_SCRIPT"; exit 1; }

ARGS=(--file "$TFVARS_FILE" --vm-key "$VM_KEY" --vm-name "$VM_NAME")
[[ -z "$MACHINE_TYPE_OVERRIDE" ]] || ARGS+=(--machine-type-override "$MACHINE_TYPE_OVERRIDE")
[[ -z "$MACHINE_SERIES" ]] || ARGS+=(--machine-series "$MACHINE_SERIES")
[[ -z "$VCPU_COUNT" ]] || ARGS+=(--vcpu-count "$VCPU_COUNT")
[[ -z "$MEMORY_GB" ]] || ARGS+=(--memory-gb "$MEMORY_GB")
[[ -z "$DISK_TYPE" ]] || ARGS+=(--disk-type "$DISK_TYPE")
[[ -z "$DISK_SIZE_GB" ]] || ARGS+=(--disk-size-gb "$DISK_SIZE_GB")
[[ -z "$BOOT_IMAGE_PROJECT" ]] || ARGS+=(--boot-image-project "$BOOT_IMAGE_PROJECT")
[[ -z "$BOOT_IMAGE_FAMILY" ]] || ARGS+=(--boot-image-family "$BOOT_IMAGE_FAMILY")
[[ -z "$ASSIGN_EXTERNAL_IP" ]] || ARGS+=(--assign-external-ip "$ASSIGN_EXTERNAL_IP")
[[ -z "$SSH_USERNAME" ]] || ARGS+=(--ssh-username "$SSH_USERNAME")
[[ -z "$SSH_PUBLIC_KEY" ]] || ARGS+=(--ssh-public-key "$SSH_PUBLIC_KEY")
[[ -z "$NETWORK_NAME" ]] || ARGS+=(--network-name "$NETWORK_NAME")
[[ -z "$SUBNETWORK_NAME" ]] || ARGS+=(--subnetwork-name "$SUBNETWORK_NAME")
[[ -z "$ALLOWED_HTTP_CIDR" ]] || ARGS+=(--allowed-http-cidr "$ALLOWED_HTTP_CIDR")
[[ -z "$ALLOWED_SSH_CIDR" ]] || ARGS+=(--allowed-ssh-cidr "$ALLOWED_SSH_CIDR")
[[ -z "$MANAGE_ORG_POLICY" ]] || ARGS+=(--manage-vm-external-ip-org-policy "$MANAGE_ORG_POLICY")

if [[ -n "$USER_GROUPS" ]]; then
  IFS=',' read -ra RAW_GROUPS <<< "$USER_GROUPS"
  for raw_group in "${RAW_GROUPS[@]}"; do
    group_name="$(echo "$raw_group" | xargs)"
    [[ -z "$group_name" ]] || ARGS+=(--user-group "$group_name")
  done
fi

OVERRIDE_FILE="$POC_DIR/backend_override.tf"

cleanup() {
  if [[ -f "$OVERRIDE_FILE" ]]; then
    log_info "Limpando arquivo temporário de override do backend ($OVERRIDE_FILE)..."
    rm -f "$OVERRIDE_FILE"
  fi
}
trap cleanup EXIT

log_info "Executando: $ADD_VM_SCRIPT ${ARGS[*]}"
"$ADD_VM_SCRIPT" "${ARGS[@]}"

log_info "Aplicando o manifesto Terraform em $POC_DIR"
cd "$POC_DIR"

if [[ -z "${GOOGLE_CREDENTIALS:-}" ]]; then
  GCP_CREDS_SECRET='<%=cypher.read("secret/gcp-terraform-ansible-samples")%>'
  if [[ -n "$GCP_CREDS_SECRET" && "$GCP_CREDS_SECRET" != *"cypher.read"* ]]; then
    log_info "Injetando GOOGLE_CREDENTIALS a partir do Cypher secret/gcp-terraform-ansible-samples..."
    export GOOGLE_CREDENTIALS="$GCP_CREDS_SECRET"
  fi
fi

if [[ -n "$TFSTATE_BUCKET" ]]; then
  log_info "Gerando backend_override.tf temporário para GCS (bucket: $TFSTATE_BUCKET, prefix: $TFSTATE_PREFIX)..."
  cat <<EOF > "$OVERRIDE_FILE"
terraform {
  backend "gcs" {
    bucket = "$TFSTATE_BUCKET"
    prefix = "$TFSTATE_PREFIX"
  }
}
EOF
fi

log_info "Inicializando Terraform..."
"$TERRAFORM_BIN" init -input=false -reconfigure
"$TERRAFORM_BIN" validate
"$TERRAFORM_BIN" apply -auto-approve -input=false

log_info "Apply concluído com sucesso."
