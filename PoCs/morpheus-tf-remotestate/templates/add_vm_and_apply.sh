#!/usr/bin/env bash
# Shell Script executado pelo Morpheus Data a partir do repositório Git.
# Os valores entre <%= customOptions.campo %> e <%= cypher.read(...) %>
# são substituídos pelo Morpheus Data em tempo de execução.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "${REPO_DIR:-}" ]; then
  if [ -d "$SCRIPT_DIR/PoCs/vm-nginx-terraform-ansible" ]; then
    REPO_DIR="$SCRIPT_DIR"
  elif [ -d "$SCRIPT_DIR/../../PoCs/vm-nginx-terraform-ansible" ]; then
    REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
  elif [ -d "$SCRIPT_DIR/../../../PoCs/vm-nginx-terraform-ansible" ]; then
    REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  elif [ -d "$PWD/PoCs/vm-nginx-terraform-ansible" ]; then
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

# Substituição direta do Morpheus Data (sintaxe nativa <%=customOptions.campo%>)
VM_KEY='<%=customOptions.vmKey%>'
VM_NAME='<%=customOptions.vmName%>'
MACHINE_TYPE_OVERRIDE='<%=customOptions.machineTypeOverride%>'
MACHINE_SERIES='<%=customOptions.machineSeries%>'
VCPU_COUNT='<%=customOptions.vcpuCount%>'
MEMORY_GB='<%=customOptions.memoryGb%>'
DISK_TYPE='<%=customOptions.diskType%>'
DISK_SIZE_GB='<%=customOptions.diskSizeGb%>'
BOOT_IMAGE_PROJECT='<%=customOptions.bootImageProject%>'
BOOT_IMAGE_FAMILY='<%=customOptions.bootImageFamily%>'
ASSIGN_EXTERNAL_IP='<%=customOptions.assignExternalIp%>'
SSH_USERNAME='<%=customOptions.sshUsername%>'
SSH_PUBLIC_KEY='<%=customOptions.sshPublicKey%>'
NETWORK_NAME='<%=customOptions.networkName%>'
SUBNETWORK_NAME='<%=customOptions.subnetworkName%>'
ALLOWED_HTTP_CIDR='<%=customOptions.allowedHttpCidr%>'
ALLOWED_SSH_CIDR='<%=customOptions.allowedSshCidr%>'
MANAGE_ORG_POLICY='<%=customOptions.manageVmExternalIpOrgPolicy%>'
USER_GROUPS='<%=customOptions.userGroups%>'

# Limpa valores "null" ou não preenchidos
[ "$VM_KEY" != "null" ] || VM_KEY=""
[ "$VM_NAME" != "null" ] || VM_NAME=""
[ "$MACHINE_TYPE_OVERRIDE" != "null" ] || MACHINE_TYPE_OVERRIDE=""
[ "$MACHINE_SERIES" != "null" ] || MACHINE_SERIES=""
[ "$VCPU_COUNT" != "null" ] || VCPU_COUNT=""
[ "$MEMORY_GB" != "null" ] || MEMORY_GB=""
[ "$DISK_TYPE" != "null" ] || DISK_TYPE=""
[ "$DISK_SIZE_GB" != "null" ] || DISK_SIZE_GB=""
[ "$BOOT_IMAGE_PROJECT" != "null" ] || BOOT_IMAGE_PROJECT=""
[ "$BOOT_IMAGE_FAMILY" != "null" ] || BOOT_IMAGE_FAMILY=""
[ "$ASSIGN_EXTERNAL_IP" != "null" ] || ASSIGN_EXTERNAL_IP=""
[ "$SSH_USERNAME" != "null" ] || SSH_USERNAME=""
[ "$SSH_PUBLIC_KEY" != "null" ] || SSH_PUBLIC_KEY=""
[ "$NETWORK_NAME" != "null" ] || NETWORK_NAME=""
[ "$SUBNETWORK_NAME" != "null" ] || SUBNETWORK_NAME=""
[ "$ALLOWED_HTTP_CIDR" != "null" ] || ALLOWED_HTTP_CIDR=""
[ "$ALLOWED_SSH_CIDR" != "null" ] || ALLOWED_SSH_CIDR=""
[ "$MANAGE_ORG_POLICY" != "null" ] || MANAGE_ORG_POLICY=""
[ "$USER_GROUPS" != "null" ] || USER_GROUPS=""

# Fallback automático: deriva vmKey de vmName se apenas um foi informado
if [ -z "$VM_KEY" ] && [ -n "$VM_NAME" ]; then
  VM_KEY="$(echo "$VM_NAME" | tr '-' '_' | tr -cd 'a-zA-Z0-9_')"
  log_info "vmKey gerado automaticamente a partir de vmName: $VM_KEY"
fi

if [ -z "$VM_NAME" ] && [ -n "$VM_KEY" ]; then
  VM_NAME="$(echo "$VM_KEY" | tr '_' '-')"
  log_info "vmName gerado automaticamente a partir de vmKey: $VM_NAME"
fi

if [ -z "$VM_KEY" ] || [ -z "$VM_NAME" ]; then
  log_error "Parâmetros obrigatórios ausentes. vmKey='$VM_KEY', vmName='$VM_NAME'."
  log_error "Certifique-se de preencher o formulário no Catálogo de Serviços do Morpheus."
  exit 1
fi

[ -d "$REPO_DIR" ] || { log_error "Repositório não encontrado em $REPO_DIR"; exit 1; }
[ -x "$ADD_VM_SCRIPT" ] || { log_error "Script não encontrado ou não executável: $ADD_VM_SCRIPT"; exit 1; }

ARGS=(--file "$TFVARS_FILE" --vm-key "$VM_KEY" --vm-name "$VM_NAME")
[ -z "$MACHINE_TYPE_OVERRIDE" ] || ARGS+=(--machine-type-override "$MACHINE_TYPE_OVERRIDE")
[ -z "$MACHINE_SERIES" ] || ARGS+=(--machine-series "$MACHINE_SERIES")
[ -z "$VCPU_COUNT" ] || ARGS+=(--vcpu-count "$VCPU_COUNT")
[ -z "$MEMORY_GB" ] || ARGS+=(--memory-gb "$MEMORY_GB")
[ -z "$DISK_TYPE" ] || ARGS+=(--disk-type "$DISK_TYPE")
[ -z "$DISK_SIZE_GB" ] || ARGS+=(--disk-size-gb "$DISK_SIZE_GB")
[ -z "$BOOT_IMAGE_PROJECT" ] || ARGS+=(--boot-image-project "$BOOT_IMAGE_PROJECT")
[ -z "$BOOT_IMAGE_FAMILY" ] || ARGS+=(--boot-image-family "$BOOT_IMAGE_FAMILY")
[ -z "$ASSIGN_EXTERNAL_IP" ] || ARGS+=(--assign-external-ip "$ASSIGN_EXTERNAL_IP")
[ -z "$SSH_USERNAME" ] || ARGS+=(--ssh-username "$SSH_USERNAME")
[ -z "$SSH_PUBLIC_KEY" ] || ARGS+=(--ssh-public-key "$SSH_PUBLIC_KEY")
[ -z "$NETWORK_NAME" ] || ARGS+=(--network-name "$NETWORK_NAME")
[ -z "$SUBNETWORK_NAME" ] || ARGS+=(--subnetwork-name "$SUBNETWORK_NAME")
[ -z "$ALLOWED_HTTP_CIDR" ] || ARGS+=(--allowed-http-cidr "$ALLOWED_HTTP_CIDR")
[ -z "$ALLOWED_SSH_CIDR" ] || ARGS+=(--allowed-ssh-cidr "$ALLOWED_SSH_CIDR")
[ -z "$MANAGE_ORG_POLICY" ] || ARGS+=(--manage-vm-external-ip-org-policy "$MANAGE_ORG_POLICY")

if [ -n "$USER_GROUPS" ]; then
  IFS=',' read -ra RAW_GROUPS <<< "$USER_GROUPS"
  for raw_group in "${RAW_GROUPS[@]}"; do
    group_name="$(echo "$raw_group" | xargs)"
    [ -z "$group_name" ] || ARGS+=(--user-group "$group_name")
  done
fi

OVERRIDE_FILE="$POC_DIR/backend_override.tf"

cleanup() {
  if [ -f "$OVERRIDE_FILE" ]; then
    log_info "Limpando arquivo temporário de override do backend ($OVERRIDE_FILE)..."
    rm -f "$OVERRIDE_FILE"
  fi
}
trap cleanup EXIT

log_info "Executando: $ADD_VM_SCRIPT ${ARGS[*]}"
"$ADD_VM_SCRIPT" "${ARGS[@]}"

log_info "Aplicando o manifesto Terraform em $POC_DIR"
cd "$POC_DIR"

if [ -z "${GOOGLE_CREDENTIALS:-}" ]; then
  GCP_CREDS_SECRET='<%=cypher.read("secret/gcp-terraform-ansible-samples")%>'
  if [ -n "$GCP_CREDS_SECRET" ] && [ "$GCP_CREDS_SECRET" != "null" ]; then
    log_info "Injetando GOOGLE_CREDENTIALS a partir do Cypher secret/gcp-terraform-ansible-samples..."
    export GOOGLE_CREDENTIALS="$GCP_CREDS_SECRET"
  fi
fi

if [ -n "$TFSTATE_BUCKET" ]; then
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
