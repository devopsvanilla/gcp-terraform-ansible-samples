#!/usr/bin/env bash
# Shell Script executado pelo Morpheus Data a partir do repositório Git.
# Os valores entre <%= customOptions[...] %> são substituídos pelo Morpheus Data
# em tempo de execução, com base no formulário preenchido pelo solicitante.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${REPO_DIR:-$(cd "$SCRIPT_DIR/../../.." && pwd)}"
POC_DIR="${POC_DIR:-$REPO_DIR/PoCs/vm-nginx-terraform-ansible}"
ADD_VM_SCRIPT="${ADD_VM_SCRIPT:-$REPO_DIR/scripts/add-vm-to-tfvars.sh}"
TFVARS_FILE="$POC_DIR/terraform.tfvars"
TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"
TFSTATE_BUCKET="${TFSTATE_BUCKET:-tfstate-devopsvanilla-samples}"
TFSTATE_PREFIX="${TFSTATE_PREFIX:-vm-nginx-terraform-ansible}"

log_info() { printf '[INFO] %s\n' "$*"; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }

VM_KEY='<%=customOptions["vmKey"]%>'
VM_NAME='<%=customOptions["vmName"]%>'
MACHINE_TYPE_OVERRIDE='<%=customOptions["machineTypeOverride"]%>'
MACHINE_SERIES='<%=customOptions["machineSeries"]%>'
VCPU_COUNT='<%=customOptions["vcpuCount"]%>'
MEMORY_GB='<%=customOptions["memoryGb"]%>'
DISK_TYPE='<%=customOptions["diskType"]%>'
DISK_SIZE_GB='<%=customOptions["diskSizeGb"]%>'
BOOT_IMAGE_PROJECT='<%=customOptions["bootImageProject"]%>'
BOOT_IMAGE_FAMILY='<%=customOptions["bootImageFamily"]%>'
ASSIGN_EXTERNAL_IP='<%=customOptions["assignExternalIp"]%>'
SSH_USERNAME='<%=customOptions["sshUsername"]%>'
SSH_PUBLIC_KEY='<%=customOptions["sshPublicKey"]%>'
NETWORK_NAME='<%=customOptions["networkName"]%>'
SUBNETWORK_NAME='<%=customOptions["subnetworkName"]%>'
ALLOWED_HTTP_CIDR='<%=customOptions["allowedHttpCidr"]%>'
ALLOWED_SSH_CIDR='<%=customOptions["allowedSshCidr"]%>'
MANAGE_ORG_POLICY='<%=customOptions["manageVmExternalIpOrgPolicy"]%>'
USER_GROUPS='<%=customOptions["userGroups"]%>'

[[ -n "$VM_KEY" ]] || { log_error "vmKey é obrigatório"; exit 1; }
[[ -n "$VM_NAME" ]] || { log_error "vmName é obrigatório"; exit 1; }
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
