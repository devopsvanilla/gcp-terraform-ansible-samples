#!/usr/bin/env bash
# Shell Script executado pelo Morpheus Data para exclusão de VM (Teardown ou Self-Service).
set -euo pipefail

# Variáveis substituídas pelo Morpheus no contexto de Instância (Teardown) ou Formulário (Operational)
INSTANCE_NAME='<%=instance.name%>'
FORM_VM_NAME='<%=customOptions.vmName%>'
FORM_VM_KEY='<%=customOptions.vmKey%>'

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }

# Limpa valores "null" ou literais não substituídos
[ "$INSTANCE_NAME" != "null" ] && [ "$INSTANCE_NAME" != "<%=instance.name%>" ] || INSTANCE_NAME=""
[ "$FORM_VM_NAME" != "null" ] && [ "$FORM_VM_NAME" != "<%=customOptions.vmName%>" ] || FORM_VM_NAME=""
[ "$FORM_VM_KEY" != "null" ] && [ "$FORM_VM_KEY" != "<%=customOptions.vmKey%>" ] || FORM_VM_KEY=""

VM_NAME="${INSTANCE_NAME:-$FORM_VM_NAME}"
VM_KEY="${FORM_VM_KEY}"

if [ -z "$VM_NAME" ] && [ -z "$VM_KEY" ]; then
  log_error "Nenhum identificador de VM informado (instance.name, customOptions.vmName ou customOptions.vmKey estão vazios)."
  exit 1
fi

log_info "Iniciando processo de remoção da VM (nome: '$VM_NAME', chave: '$VM_KEY')..."

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
    REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
  fi
fi

POC_DIR="${POC_DIR:-$REPO_DIR/PoCs/vm-nginx-terraform-ansible}"
REMOVE_VM_SCRIPT="${REMOVE_VM_SCRIPT:-$REPO_DIR/scripts/remove-vm-from-tfvars.sh}"
TFVARS_FILE="$POC_DIR/terraform.tfvars"
TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"
TFSTATE_BUCKET="${TFSTATE_BUCKET:-tfstate-devopsvanilla-samples}"
TFSTATE_PREFIX="${TFSTATE_PREFIX:-vm-nginx-terraform-ansible}"

[ -d "$POC_DIR" ] || { log_error "Diretório da PoC não encontrado em $POC_DIR"; exit 1; }
[ -f "$REMOVE_VM_SCRIPT" ] || { log_error "Script de remoção não encontrado em $REMOVE_VM_SCRIPT"; exit 1; }
chmod +x "$REMOVE_VM_SCRIPT" 2>/dev/null || true

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

ARGS=(--file "$TFVARS_FILE")
[ -z "$VM_KEY" ] || ARGS+=(--vm-key "$VM_KEY")
[ -z "$VM_NAME" ] || ARGS+=(--vm-name "$VM_NAME")

log_info "Executando remoção no tfvars: bash $REMOVE_VM_SCRIPT ${ARGS[*]}"
bash "$REMOVE_VM_SCRIPT" "${ARGS[@]}"

log_info "Aplicando mudanças no Terraform para desprovisionar recursos na GCP e atualizar o tfstate..."
"$TERRAFORM_BIN" validate
"$TERRAFORM_BIN" apply -auto-approve -input=false

log_info "Desprovisionamento concluído com sucesso."
