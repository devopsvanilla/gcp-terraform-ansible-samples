#!/usr/bin/env bash
# Shell Script executado pelo Morpheus Data a partir do repositório Git.
set -euo pipefail

# Variáveis substituídas pelo Morpheus
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

# Limpa valores "null"
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

# Normaliza booleanos do Morpheus (checkboxes retornam 'on', 'off', 'true', 'false', '1', '0')
case "$(echo "$ASSIGN_EXTERNAL_IP" | tr '[:upper:]' '[:lower:]')" in
  true|on|yes|1) ASSIGN_EXTERNAL_IP="true" ;;
  false|off|no|0|"") ASSIGN_EXTERNAL_IP="false" ;;
esac

case "$(echo "$MANAGE_ORG_POLICY" | tr '[:upper:]' '[:lower:]')" in
  true|on|yes|1) MANAGE_ORG_POLICY="true" ;;
  false|off|no|0|"") MANAGE_ORG_POLICY="false" ;;
esac

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
[ -f "$ADD_VM_SCRIPT" ] || { log_error "Script não encontrado em $ADD_VM_SCRIPT"; exit 1; }
chmod +x "$ADD_VM_SCRIPT" 2>/dev/null || true

# Inicializa o terraform.tfvars no clone do Morpheus se ainda não existir
if [ ! -f "$TFVARS_FILE" ]; then
  if [ -f "$POC_DIR/terraform.tfvars-SAMPLE" ]; then
    log_info "terraform.tfvars não encontrado no clone; inicializando a partir de terraform.tfvars-SAMPLE..."
    cp "$POC_DIR/terraform.tfvars-SAMPLE" "$TFVARS_FILE"
  else
    log_info "Criando terraform.tfvars base em $TFVARS_FILE..."
    cat <<'EOF' > "$TFVARS_FILE"
poc_name                         = "vm-nginx-terraform-ansible"
project_id                       = "poc-terraform-ansible"
region                           = "us-central1"
zone                             = "us-central1-a"
manage_vm_external_ip_org_policy = true
network_name                     = "default"
allowed_http_cidr                = "0.0.0.0/0"
allowed_ssh_cidr                 = "0.0.0.0/0"
run_ansible                      = false

vms = {}
EOF
  fi
fi

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
CREDS_FILE=""

cleanup() {
  if [ -f "$OVERRIDE_FILE" ]; then
    log_info "Limpando arquivo temporário de override do backend ($OVERRIDE_FILE)..."
    rm -f "$OVERRIDE_FILE"
  fi
  if [ -n "$CREDS_FILE" ] && [ -f "$CREDS_FILE" ]; then
    log_info "Limpando arquivo temporário de credenciais GCP ($CREDS_FILE)..."
    rm -f "$CREDS_FILE"
  fi
}
trap cleanup EXIT

cd "$POC_DIR"

if [ -z "${GOOGLE_CREDENTIALS:-}" ] && [ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
  GCP_CREDS_SECRET='<%=cypher.read("secret/gcp-terraform-ansible-samples")%>'
  if [ -n "$GCP_CREDS_SECRET" ] && [ "$GCP_CREDS_SECRET" != "null" ]; then
    log_info "Injetando credenciais GCP a partir do Cypher secret/gcp-terraform-ansible-samples..."
    CREDS_FILE="$(mktemp /tmp/gcp_creds_XXXXXX.json)"
    chmod 600 "$CREDS_FILE"
    printf '%s' "$GCP_CREDS_SECRET" > "$CREDS_FILE"
    export GOOGLE_APPLICATION_CREDENTIALS="$CREDS_FILE"
    export GOOGLE_CREDENTIALS="$GCP_CREDS_SECRET"
  else
    log_info "Aviso: Cypher secret/gcp-terraform-ansible-samples retornou vazio/null ou não configurado."
  fi
elif [ -n "${GOOGLE_CREDENTIALS:-}" ] && [ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
  if [ -f "$GOOGLE_CREDENTIALS" ]; then
    export GOOGLE_APPLICATION_CREDENTIALS="$GOOGLE_CREDENTIALS"
  else
    log_info "Gravando GOOGLE_CREDENTIALS em arquivo temporário para o backend GCS..."
    CREDS_FILE="$(mktemp /tmp/gcp_creds_XXXXXX.json)"
    chmod 600 "$CREDS_FILE"
    printf '%s' "$GOOGLE_CREDENTIALS" > "$CREDS_FILE"
    export GOOGLE_APPLICATION_CREDENTIALS="$CREDS_FILE"
  fi
fi

if [ -n "$TFSTATE_BUCKET" ]; then
  log_info "Gerando backend_override.tf temporário para GCS (bucket: $TFSTATE_BUCKET, prefix: $TFSTATE_PREFIX)..."
  if [ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ] && [ -f "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
    cat <<EOF > "$OVERRIDE_FILE"
terraform {
  backend "gcs" {
    bucket      = "$TFSTATE_BUCKET"
    prefix      = "$TFSTATE_PREFIX"
    credentials = "$GOOGLE_APPLICATION_CREDENTIALS"
  }
}
EOF
  else
    cat <<EOF > "$OVERRIDE_FILE"
terraform {
  backend "gcs" {
    bucket = "$TFSTATE_BUCKET"
    prefix = "$TFSTATE_PREFIX"
  }
}
EOF
  fi
fi

log_info "Inicializando Terraform em $POC_DIR..."
"$TERRAFORM_BIN" init -input=false -reconfigure

log_info "Executando: bash $ADD_VM_SCRIPT ${ARGS[*]}"
bash "$ADD_VM_SCRIPT" "${ARGS[@]}"

log_info "Validando e aplicando o manifesto Terraform em $POC_DIR..."
"$TERRAFORM_BIN" validate
"$TERRAFORM_BIN" apply -auto-approve -input=false

log_info "Apply concluído com sucesso."
