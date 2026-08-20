#!/usr/bin/env bash
# Shell Script executado pelo Morpheus Data a partir do repositório Git.
# As opções customizadas preenchidas no formulário do Morpheus são passadas
# automaticamente como variáveis de ambiente pelo Morpheus Data.
set -euo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"

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

# Lê as opções injetadas pelo Morpheus via variáveis de ambiente
VM_KEY="${vmKey:-${VM_KEY:-${MORPHEUS_CUSTOM_OPTIONS_VMKEY:-${vm_key:-}}}}"
VM_NAME="${vmName:-${VM_NAME:-${MORPHEUS_CUSTOM_OPTIONS_VMNAME:-${vm_name:-}}}}"
MACHINE_TYPE_OVERRIDE="${machineTypeOverride:-${MACHINE_TYPE_OVERRIDE:-${machine_type_override:-}}}"
MACHINE_SERIES="${machineSeries:-${MACHINE_SERIES:-${machine_series:-}}}"
VCPU_COUNT="${vcpuCount:-${VCPU_COUNT:-${vcpu_count:-}}}"
MEMORY_GB="${memoryGb:-${MEMORY_GB:-${memory_gb:-}}}"
DISK_TYPE="${diskType:-${DISK_TYPE:-${disk_type:-}}}"
DISK_SIZE_GB="${diskSizeGb:-${DISK_SIZE_GB:-${disk_size_gb:-}}}"
BOOT_IMAGE_PROJECT="${bootImageProject:-${BOOT_IMAGE_PROJECT:-${boot_image_project:-}}}"
BOOT_IMAGE_FAMILY="${bootImageFamily:-${BOOT_IMAGE_FAMILY:-${boot_image_family:-}}}"
ASSIGN_EXTERNAL_IP="${assignExternalIp:-${ASSIGN_EXTERNAL_IP:-${assign_external_ip:-}}}"
SSH_USERNAME="${sshUsername:-${SSH_USERNAME:-${ssh_username:-}}}"
SSH_PUBLIC_KEY="${sshPublicKey:-${SSH_PUBLIC_KEY:-${ssh_public_key:-}}}"
NETWORK_NAME="${networkName:-${NETWORK_NAME:-${network_name:-}}}"
SUBNETWORK_NAME="${subnetworkName:-${SUBNETWORK_NAME:-${subnetwork_name:-}}}"
ALLOWED_HTTP_CIDR="${allowedHttpCidr:-${ALLOWED_HTTP_CIDR:-${allowed_http_cidr:-}}}"
ALLOWED_SSH_CIDR="${allowedSshCidr:-${ALLOWED_SSH_CIDR:-${allowed_ssh_cidr:-}}}"
MANAGE_ORG_POLICY="${manageVmExternalIpOrgPolicy:-${MANAGE_VM_EXTERNAL_IP_ORG_POLICY:-${manage_vm_external_ip_org_policy:-}}}"
USER_GROUPS="${userGroups:-${USER_GROUPS:-${user_groups:-}}}"

# Limpa valores literais "null"
for var_name in VM_KEY VM_NAME MACHINE_TYPE_OVERRIDE MACHINE_SERIES VCPU_COUNT MEMORY_GB DISK_TYPE DISK_SIZE_GB BOOT_IMAGE_PROJECT BOOT_IMAGE_FAMILY ASSIGN_EXTERNAL_IP SSH_USERNAME SSH_PUBLIC_KEY NETWORK_NAME SUBNETWORK_NAME ALLOWED_HTTP_CIDR ALLOWED_SSH_CIDR MANAGE_ORG_POLICY USER_GROUPS; do
  if [[ "${!var_name}" == "null" ]]; then
    eval "$var_name=''"
  fi
done

# Fallbacks automáticos para vmKey / vmName
if [[ -z "$VM_KEY" && -n "$VM_NAME" ]]; then
  VM_KEY="$(echo "$VM_NAME" | tr '-' '_' | tr -cd 'a-zA-Z0-9_')"
  log_info "vmKey preenchido automaticamente a partir de vmName: $VM_KEY"
fi

if [[ -z "$VM_NAME" && -n "$VM_KEY" ]]; then
  VM_NAME="$(echo "$VM_KEY" | tr '_' '-')"
  log_info "vmName preenchido automaticamente a partir de vmKey: $VM_NAME"
fi

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
  if [[ -f "$REPO_DIR/scripts/gcp-key.json" ]]; then
    log_info "Carregando GOOGLE_CREDENTIALS a partir de $REPO_DIR/scripts/gcp-key.json..."
    export GOOGLE_CREDENTIALS="$(cat "$REPO_DIR/scripts/gcp-key.json")"
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
