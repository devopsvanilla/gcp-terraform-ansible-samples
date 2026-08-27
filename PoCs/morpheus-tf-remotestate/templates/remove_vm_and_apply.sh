#!/usr/bin/env bash
# Shell Script executado pelo Morpheus Data para exclusão de VM (Teardown ou Self-Service).
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

# Variáveis substituídas pelo Morpheus no contexto de Instância (Teardown) ou Formulário (Operational)
INSTANCE_NAME="$(get_param '<%= binding.hasVariable("instance") && instance ? instance.name : "" %>' instance_name morpheus_instance_name INSTANCE_NAME)"
FORM_VM_NAME="$(get_param '<%= binding.hasVariable("customOptions") && customOptions?.vmName ? customOptions.vmName : "" %>' customOption_vmName customOptions_vmName morpheus_customOption_vmName morpheus_customOptions_vmName vmName VM_NAME vm_name)"
FORM_VM_KEY="$(get_param '<%= binding.hasVariable("customOptions") && customOptions?.vmKey ? customOptions.vmKey : "" %>' customOption_vmKey customOptions_vmKey morpheus_customOption_vmKey morpheus_customOptions_vmKey vmKey VM_KEY vm_key)"

# Injeção de credenciais GCP via Cypher ou Variável de Ambiente
GCP_CREDS_SECRET="$(get_param '<%=cypher.read("secret/gcp-terraform-ansible-samples")%>' GCP_CREDS_SECRET GOOGLE_CREDENTIALS GCP_CREDENTIALS)"

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }

VM_NAME="${INSTANCE_NAME:-$FORM_VM_NAME}"
VM_KEY="${FORM_VM_KEY}"

if [ -z "$VM_NAME" ] && [ -z "$VM_KEY" ]; then
  log_error "Nenhum identificador de VM informado (instance.name, customOptions.vmName ou customOptions.vmKey estão vazios)."
  exit 1
fi

log_info "Iniciando processo de remoção da VM (nome: '$VM_NAME', chave: '$VM_KEY')..."

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
    REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
  fi
fi

POC_DIR="${POC_DIR:-$REPO_DIR/PoCs/gcp-create-vm-gcstate}"
TFVARS_FILE="$POC_DIR/terraform.tfvars"
TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"
TFSTATE_BUCKET="${TFSTATE_BUCKET:-tfstate-devopsvanilla-samples}"
TFSTATE_PREFIX="${TFSTATE_PREFIX:-gcp-create-vm-gcstate}"

[ -d "$POC_DIR" ] || { log_error "Diretório da PoC não encontrado em $POC_DIR"; exit 1; }

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

# Normalização e fallback de identificadores
if [ -z "$VM_KEY" ] && [ -n "$VM_NAME" ]; then
  VM_KEY="$(echo "$VM_NAME" | tr '-' '_' | tr -cd 'a-zA-Z0-9_')"
  log_info "vmKey derivado automaticamente a partir de vmName: $VM_KEY"
fi

if [ -z "$VM_NAME" ] && [ -n "$VM_KEY" ]; then
  VM_NAME="$(echo "$VM_KEY" | tr '_' '-')"
  log_info "vmName derivado automaticamente a partir de vmKey: $VM_NAME"
fi

if [ -z "$VM_KEY" ] && [ -z "$VM_NAME" ]; then
  log_error "Nenhum identificador de VM informado (instance.name, customOptions.vmName ou customOptions.vmKey estão vazios)."
  exit 1
fi

log_info "Iniciando processo de remoção da VM (nome: '$VM_NAME', chave: '$VM_KEY', project: '$FINAL_PROJECT_ID')..."

# 1. Define o prefixo isolado no GCS para esta VM específica
INSTANCE_STATE_PREFIX="${TFSTATE_PREFIX}/${VM_KEY}"
log_info "Configurando estado remoto isolado no GCS (bucket: $TFSTATE_BUCKET, prefix: $INSTANCE_STATE_PREFIX)..."

# 2. Gera backend_override.tf temporário para GCS
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

# 3. Executa terraform init, validate e destroy
log_info "Inicializando Terraform em $POC_DIR (reconfigure para prefix $INSTANCE_STATE_PREFIX)..."
"$TERRAFORM_BIN" init -input=false -reconfigure

log_info "Executando terraform destroy para a VM '$VM_NAME' (chave: '$VM_KEY')..."
"$TERRAFORM_BIN" destroy -auto-approve -input=false -var="project_id=$FINAL_PROJECT_ID" || true

# 4. Limpeza de resíduos de firewall no GCP (garantia pós-destroy)
VM_KEY_SLUG="$(echo "$VM_KEY" | tr '[:upper:]' '[:lower:]' | tr '_' '-')"
if command -v gcloud >/dev/null 2>&1; then
  for fw_rule in "gcp-create-vm-gcstate-${VM_KEY_SLUG}-allow-http" "gcp-create-vm-gcstate-${VM_KEY_SLUG}-allow-ssh"; do
    if gcloud compute firewall-rules describe "$fw_rule" --project="$FINAL_PROJECT_ID" >/dev/null 2>&1; then
      log_info "Limpando regra de firewall residual no GCP ($fw_rule)..."
      gcloud compute firewall-rules delete "$fw_rule" --project="$FINAL_PROJECT_ID" --quiet >/dev/null 2>&1 || true
    fi
  done
fi

# 5. Limpeza completa do estado e versões no bucket GCS
if [ -n "$TFSTATE_BUCKET" ] && command -v gcloud >/dev/null 2>&1; then
  log_info "Limpando arquivos de estado da VM no GCS (gs://$TFSTATE_BUCKET/$INSTANCE_STATE_PREFIX)..."
  gcloud storage rm --recursive --all-versions "gs://${TFSTATE_BUCKET}/${INSTANCE_STATE_PREFIX}" --quiet >/dev/null 2>&1 || \
  gcloud storage rm --recursive "gs://${TFSTATE_BUCKET}/${INSTANCE_STATE_PREFIX}" --quiet >/dev/null 2>&1 || \
  gsutil -m rm -r "gs://${TFSTATE_BUCKET}/${INSTANCE_STATE_PREFIX}" >/dev/null 2>&1 || true
fi

log_info "Desprovisionamento da VM '$VM_NAME' concluído com sucesso."
