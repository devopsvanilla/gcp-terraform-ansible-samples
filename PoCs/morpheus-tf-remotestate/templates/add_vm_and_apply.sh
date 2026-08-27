#!/usr/bin/env bash
# Shell Script executado pelo Morpheus Data a partir do repositório Git.
set -euo pipefail

# Função para resolver parâmetros tanto por interpolação ERB quanto por variáveis de ambiente injetadas pelo Morpheus
get_param() {
  local erb_val="$1"
  shift
  if [ -n "$erb_val" ] && [ "$erb_val" != "null" ] && [[ "$erb_val" != *"<%"* ]]; then
    echo "$erb_val"
    return
  fi
  for var_name in "$@"; do
    local val="${!var_name:-}"
    if [ -n "$val" ] && [ "$val" != "null" ] && [[ "$val" != *"<%"* ]]; then
      echo "$val"
      return
    fi
  done
  echo ""
}

# Resolução de Variáveis
VM_KEY="$(get_param '<%=customOptions.vmKey%>' customOption_vmKey customOptions_vmKey morpheus_customOption_vmKey morpheus_customOptions_vmKey vmKey VM_KEY vm_key)"
VM_NAME="$(get_param '<%=customOptions.vmName%>' customOption_vmName customOptions_vmName morpheus_customOption_vmName morpheus_customOptions_vmName vmName VM_NAME vm_name instance_name morpheus_instance_name INSTANCE_NAME)"
MACHINE_TYPE_OVERRIDE="$(get_param '<%=customOptions.machineTypeOverride%>' customOption_machineTypeOverride customOptions_machineTypeOverride morpheus_customOption_machineTypeOverride morpheus_customOptions_machineTypeOverride machineTypeOverride machine_type_override)"
MACHINE_SERIES="$(get_param '<%=customOptions.machineSeries%>' customOption_machineSeries customOptions_machineSeries morpheus_customOption_machineSeries morpheus_customOptions_machineSeries machineSeries machine_series)"
VCPU_COUNT="$(get_param '<%=customOptions.vcpuCount%>' customOption_vcpuCount customOptions_vcpuCount morpheus_customOption_vcpuCount morpheus_customOptions_vcpuCount vcpuCount vcpu_count)"
MEMORY_GB="$(get_param '<%=customOptions.memoryGb%>' customOption_memoryGb customOptions_memoryGb morpheus_customOption_memoryGb morpheus_customOptions_memoryGb memoryGb memory_gb)"
DISK_TYPE="$(get_param '<%=customOptions.diskType%>' customOption_diskType customOptions_diskType morpheus_customOption_diskType morpheus_customOptions_diskType diskType disk_type)"
DISK_SIZE_GB="$(get_param '<%=customOptions.diskSizeGb%>' customOption_diskSizeGb customOptions_diskSizeGb morpheus_customOption_diskSizeGb morpheus_customOptions_diskSizeGb diskSizeGb disk_size_gb)"
BOOT_IMAGE_PROJECT="$(get_param '<%=customOptions.bootImageProject%>' customOption_bootImageProject customOptions_bootImageProject morpheus_customOption_bootImageProject morpheus_customOptions_bootImageProject bootImageProject boot_image_project)"
BOOT_IMAGE_FAMILY="$(get_param '<%=customOptions.bootImageFamily%>' customOption_bootImageFamily customOptions_bootImageFamily morpheus_customOption_bootImageFamily morpheus_customOptions_bootImageFamily bootImageFamily boot_image_family)"
ASSIGN_EXTERNAL_IP="$(get_param '<%=customOptions.assignExternalIp%>' customOption_assignExternalIp customOptions_assignExternalIp morpheus_customOption_assignExternalIp morpheus_customOptions_assignExternalIp assignExternalIp assign_external_ip)"
SSH_USERNAME="$(get_param '<%=customOptions.sshUsername%>' customOption_sshUsername customOptions_sshUsername morpheus_customOption_sshUsername morpheus_customOptions_sshUsername sshUsername ssh_username)"
SSH_PUBLIC_KEY="$(get_param '<%=customOptions.sshPublicKey%>' customOption_sshPublicKey customOptions_sshPublicKey morpheus_customOption_sshPublicKey morpheus_customOptions_sshPublicKey sshPublicKey ssh_public_key)"
NETWORK_NAME="$(get_param '<%=customOptions.networkName%>' customOption_networkName customOptions_networkName morpheus_customOption_networkName morpheus_customOptions_networkName networkName network_name)"
SUBNETWORK_NAME="$(get_param '<%=customOptions.subnetworkName%>' customOption_subnetworkName customOptions_subnetworkName morpheus_customOption_subnetworkName morpheus_customOptions_subnetworkName subnetworkName subnetwork_name)"
ALLOWED_HTTP_CIDR="$(get_param '<%=customOptions.allowedHttpCidr%>' customOption_allowedHttpCidr customOptions_allowedHttpCidr morpheus_customOption_allowedHttpCidr morpheus_customOptions_allowedHttpCidr allowedHttpCidr allowed_http_cidr)"
ALLOWED_SSH_CIDR="$(get_param '<%=customOptions.allowedSshCidr%>' customOption_allowedSshCidr customOptions_allowedSshCidr morpheus_customOption_allowedSshCidr morpheus_customOptions_allowedSshCidr allowedSshCidr allowed_ssh_cidr)"
MANAGE_ORG_POLICY="$(get_param '<%=customOptions.manageVmExternalIpOrgPolicy%>' customOption_manageVmExternalIpOrgPolicy customOptions_manageVmExternalIpOrgPolicy morpheus_customOption_manageVmExternalIpOrgPolicy morpheus_customOptions_manageVmExternalIpOrgPolicy manageVmExternalIpOrgPolicy manage_vm_external_ip_org_policy)"
USER_GROUPS="$(get_param '<%=customOptions.userGroups%>' customOption_userGroups customOptions_userGroups morpheus_customOption_userGroups morpheus_customOptions_userGroups userGroups user_groups)"

# Injeção de credenciais GCP via Cypher ou Variável de Ambiente
GCP_CREDS_SECRET="$(get_param '<%=cypher.read("secret/gcp-terraform-ansible-samples")%>' GCP_CREDS_SECRET GOOGLE_CREDENTIALS GCP_CREDENTIALS)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "${REPO_DIR:-}" ]; then
  if [ -d "$SCRIPT_DIR/PoCs/gcp-create-vm-gcstate" ]; then
    REPO_DIR="$SCRIPT_DIR"
  elif [ -d "$SCRIPT_DIR/../../PoCs/gcp-create-vm-gcstate" ]; then
    REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
  elif [ -d "$SCRIPT_DIR/../../../PoCs/gcp-create-vm-gcstate" ]; then
    REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  elif [ -d "$PWD/PoCs/gcp-create-vm-gcstate" ]; then
    REPO_DIR="$PWD"
  else
    REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  fi
fi

POC_DIR="${POC_DIR:-$REPO_DIR/PoCs/gcp-create-vm-gcstate}"
TFVARS_FILE="$POC_DIR/terraform.tfvars"
TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"
TFSTATE_BUCKET="${TFSTATE_BUCKET:-tfstate-devopsvanilla-samples}"
TFSTATE_PREFIX="${TFSTATE_PREFIX:-gcp-create-vm-gcstate}"

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }

# Normaliza booleanos do Morpheus
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

log_info "Parâmetros recebidos: vmKey='$VM_KEY', vmName='$VM_NAME', series='${MACHINE_SERIES:-e2}', type='${MACHINE_TYPE_OVERRIDE:-}'"

[ -d "$REPO_DIR" ] || { log_error "Repositório não encontrado em $REPO_DIR"; exit 1; }

OVERRIDE_FILE="$POC_DIR/backend_override.tf"
CREDS_FILE=""

cleanup() {
  if [ -f "$OVERRIDE_FILE" ]; then
    log_info "Limpando arquivo temporário de override do backend ($OVERRIDE_FILE)..."
    rm -f "$OVERRIDE_FILE"
  fi
  if [ -f "$TFVARS_FILE" ]; then
    log_info "Limpando arquivo efêmero de variáveis ($TFVARS_FILE)..."
    rm -f "$TFVARS_FILE"
  fi
  if [ -n "$CREDS_FILE" ] && [ -f "$CREDS_FILE" ]; then
    log_info "Limpando arquivo temporário de credenciais GCP ($CREDS_FILE)..."
    rm -f "$CREDS_FILE"
  fi
}
trap cleanup EXIT

cd "$POC_DIR"

if [ -z "${GOOGLE_CREDENTIALS:-}" ] && [ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
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

# Detecta project_id a partir do arquivo de credenciais
DETECTED_PROJECT_ID=""
if [ -n "${CREDS_FILE:-}" ] && [ -f "$CREDS_FILE" ]; then
  DETECTED_PROJECT_ID="$(python3 -c "import json; data=json.load(open('$CREDS_FILE')); print(data.get('project_id', ''))" 2>/dev/null || true)"
elif [ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ] && [ -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
  DETECTED_PROJECT_ID="$(python3 -c "import json; data=json.load(open('$GOOGLE_APPLICATION_CREDENTIALS')); print(data.get('project_id', ''))" 2>/dev/null || true)"
fi

FINAL_PROJECT_ID="${DETECTED_PROJECT_ID:-poc-terraform-ansible}"

# Formata grupos de usuário para sintaxe HCL
if [ -n "$USER_GROUPS" ]; then
  IFS=',' read -ra RAW_GROUPS <<< "$USER_GROUPS"
  FORMATTED_GROUPS=""
  for raw_group in "${RAW_GROUPS[@]}"; do
    group_name="$(echo "$raw_group" | xargs)"
    if [ -n "$group_name" ]; then
      if [ -n "$FORMATTED_GROUPS" ]; then
        FORMATTED_GROUPS="${FORMATTED_GROUPS}, \"${group_name}\""
      else
        FORMATTED_GROUPS="\"${group_name}\""
      fi
    fi
  done
  USER_GROUPS_HCL="[${FORMATTED_GROUPS}]"
else
  USER_GROUPS_HCL="[\"sudo\"]"
fi

# 1. Gera o arquivo terraform.tfvars plano exclusivo para esta VM
log_info "Gerando manifesto terraform.tfvars direto para a VM '$VM_NAME' ($VM_KEY)..."
cat <<EOF > "$TFVARS_FILE"
poc_name                         = "gcp-create-vm-gcstate"
project_id                       = "$FINAL_PROJECT_ID"
region                           = "us-central1"
zone                             = "us-central1-a"
name                             = "$VM_NAME"
vm_name                          = "$VM_NAME"
machine_type_override            = "${MACHINE_TYPE_OVERRIDE:-e2-micro}"
machine_series                   = "${MACHINE_SERIES:-e2}"
vcpu_count                       = ${VCPU_COUNT:-1}
memory_gb                        = ${MEMORY_GB:-1}
disk_type                        = "${DISK_TYPE:-pd-standard}"
disk_size_gb                     = ${DISK_SIZE_GB:-30}
boot_image_project               = "${BOOT_IMAGE_PROJECT:-debian-cloud}"
boot_image_family                = "${BOOT_IMAGE_FAMILY:-debian-12}"
assign_external_ip               = ${ASSIGN_EXTERNAL_IP:-true}
ssh_username                     = "${SSH_USERNAME:-devopsvanilla}"
ssh_public_key                   = "${SSH_PUBLIC_KEY:-}"
network_name                     = "${NETWORK_NAME:-default}"
subnetwork_name                  = "${SUBNETWORK_NAME:-}"
allowed_http_cidr                = "${ALLOWED_HTTP_CIDR:-0.0.0.0/0}"
allowed_ssh_cidr                 = "${ALLOWED_SSH_CIDR:-0.0.0.0/0}"
manage_vm_external_ip_org_policy = ${MANAGE_ORG_POLICY:-false}
user_groups                      = ${USER_GROUPS_HCL}
EOF

# 2. Define o prefixo isolado no GCS para esta VM específica
INSTANCE_STATE_PREFIX="${TFSTATE_PREFIX}/${VM_KEY}"
log_info "Configurando estado remoto isolado no GCS (bucket: $TFSTATE_BUCKET, prefix: $INSTANCE_STATE_PREFIX)..."

# 3. Gera arquivo temporário backend_override.tf apontando para o prefixo da instância
if [ -n "$TFSTATE_BUCKET" ]; then
  if [ -n "${GOOGLE_APPLICATION_CREDENTIALS:-}" ] && [ -f "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
    cat <<EOF > "$OVERRIDE_FILE"
terraform {
  backend "gcs" {
    bucket      = "$TFSTATE_BUCKET"
    prefix      = "$INSTANCE_STATE_PREFIX"
    credentials = "$GOOGLE_APPLICATION_CREDENTIALS"
  }
}
EOF
  else
    cat <<EOF > "$OVERRIDE_FILE"
terraform {
  backend "gcs" {
    bucket = "$TFSTATE_BUCKET"
    prefix = "$INSTANCE_STATE_PREFIX"
  }
}
EOF
  fi
fi

# 4. Inicializa o Terraform com reconfigure para o prefixo da instância
log_info "Inicializando Terraform em $POC_DIR (reconfigure para prefix $INSTANCE_STATE_PREFIX)..."
"$TERRAFORM_BIN" init -input=false -reconfigure

# 5. Pré-checagem e sanitização de recursos órfãos no GCP (evita erro 409 alreadyExists)
log_info "Executando pre-flight check de recursos órfãos no GCP..."
VM_KEY_SLUG="$(echo "$VM_KEY" | tr '[:upper:]' '[:lower:]' | tr '_' '-')"
if command -v gcloud >/dev/null 2>&1; then
  # Regras de Firewall órfãs
  for fw_rule in "gcp-create-vm-gcstate-${VM_KEY_SLUG}-allow-http" "gcp-create-vm-gcstate-${VM_KEY_SLUG}-allow-ssh"; do
    if gcloud compute firewall-rules describe "$fw_rule" --project="$FINAL_PROJECT_ID" >/dev/null 2>&1; then
      if ! "$TERRAFORM_BIN" state list 2>/dev/null | grep -q "google_compute_firewall.*${VM_KEY}"; then
        log_warn "Regra de firewall órfã detectada no GCP ($fw_rule) fora do tfstate atual. Removendo resquício..."
        gcloud compute firewall-rules delete "$fw_rule" --project="$FINAL_PROJECT_ID" --quiet >/dev/null 2>&1 || true
      fi
    fi
  done

  # Instância Compute Engine órfã
  if gcloud compute instances describe "$VM_NAME" --zone="us-central1-a" --project="$FINAL_PROJECT_ID" >/dev/null 2>&1; then
    if ! "$TERRAFORM_BIN" state list 2>/dev/null | grep -q "google_compute_instance.vm"; then
      log_warn "Instância Compute Engine órfã detectada no GCP ($VM_NAME) fora do tfstate atual. Removendo resquício..."
      gcloud compute instances delete "$VM_NAME" --zone="us-central1-a" --project="$FINAL_PROJECT_ID" --quiet >/dev/null 2>&1 || true
    fi
  fi
fi

log_info "Validando e aplicando o manifesto Terraform para a VM '$VM_NAME'..."
"$TERRAFORM_BIN" validate
"$TERRAFORM_BIN" apply -auto-approve -input=false

log_info "Provisionamento da VM '$VM_NAME' concluído com sucesso com estado isolado em gs://$TFSTATE_BUCKET/$INSTANCE_STATE_PREFIX/default.tfstate."
