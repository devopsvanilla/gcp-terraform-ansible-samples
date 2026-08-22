#!/usr/bin/env bash
# Shell Script executado pelo Morpheus Data para exclusão de VM (Teardown ou Self-Service).
set -euo pipefail

# Variáveis substituídas pelo Morpheus no contexto de Instância (Teardown) ou Formulário (Operational)
INSTANCE_NAME='<%= binding.hasVariable("instance") && instance ? instance.name : "" %>'
FORM_VM_NAME='<%= binding.hasVariable("customOptions") && customOptions?.vmName ? customOptions.vmName : "" %>'
FORM_VM_KEY='<%= binding.hasVariable("customOptions") && customOptions?.vmKey ? customOptions.vmKey : "" %>'

# Injeção de credenciais GCP, chaves do Cypher e contexto de API Morpheus
GCP_CREDS_SECRET='<%=cypher.read("secret/gcp-terraform-ansible-samples")%>'
CYPHER_TFVARS_VALUE='<%=cypher.read("secret/tfvars-gcp-create-vm-gcstate")%>'
ERB_MORPHEUS_API_URL='<%= binding.hasVariable("morpheus") ? (morpheus?.getAt("apiUrl") ?: morpheus?.getAt("api_url") ?: morpheus?.getAt("applianceUrl") ?: "") : "" %>'
ERB_MORPHEUS_TOKEN='<%= binding.hasVariable("morpheus") ? (morpheus?.getAt("apiAccessToken") ?: morpheus?.getAt("apiToken") ?: morpheus?.getAt("token") ?: "") : "" %>'
CYPHER_MORPHEUS_URL='<%=cypher.read("secret/morpheus-api-url")%>'
CYPHER_MORPHEUS_TOKEN='<%=cypher.read("secret/morpheus-api-token")%>'
CYPHER_TFVARS_KEY="secret/tfvars-gcp-create-vm-gcstate"

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }

# Limpa valores "null"
[ "$INSTANCE_NAME" != "null" ] || INSTANCE_NAME=""
[ "$FORM_VM_NAME" != "null" ] || FORM_VM_NAME=""
[ "$FORM_VM_KEY" != "null" ] || FORM_VM_KEY=""
[ "$ERB_MORPHEUS_API_URL" != "null" ] || ERB_MORPHEUS_API_URL=""
[ "$ERB_MORPHEUS_TOKEN" != "null" ] || ERB_MORPHEUS_TOKEN=""
[ "$CYPHER_MORPHEUS_URL" != "null" ] || CYPHER_MORPHEUS_URL=""
[ "$CYPHER_MORPHEUS_TOKEN" != "null" ] || CYPHER_MORPHEUS_TOKEN=""

MORPHEUS_API_URL="${MORPHEUS_API_URL:-${MORPHEUS_APPLIANCE_URL:-${MORPHEUS_URL:-${ERB_MORPHEUS_API_URL:-${CYPHER_MORPHEUS_URL:-}}}}}"
MORPHEUS_TOKEN="${MORPHEUS_TOKEN:-${MORPHEUS_API_TOKEN:-${MORPHEUS_ACCESS_TOKEN:-${ERB_MORPHEUS_TOKEN:-${CYPHER_MORPHEUS_TOKEN:-}}}}}"

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
REMOVE_VM_SCRIPT="${REMOVE_VM_SCRIPT:-$REPO_DIR/scripts/remove-vm-from-tfvars.sh}"
TFVARS_FILE="$POC_DIR/terraform.tfvars"
TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"
TFSTATE_BUCKET="${TFSTATE_BUCKET:-tfstate-devopsvanilla-samples}"
TFSTATE_PREFIX="${TFSTATE_PREFIX:-gcp-create-vm-gcstate}"

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

# 1. Recupera o conteúdo de terraform.tfvars a partir do Morpheus Cypher
log_info "Carregando terraform.tfvars a partir do Cypher ($CYPHER_TFVARS_KEY)..."
if [ -n "$CYPHER_TFVARS_VALUE" ] && [ "$CYPHER_TFVARS_VALUE" != "null" ]; then
  log_info "Conteúdo do Cypher recuperado via interpolação."
  printf '%s\n' "$CYPHER_TFVARS_VALUE" > "$TFVARS_FILE"
elif [ -n "${MORPHEUS_API_URL:-}" ] && [ -n "${MORPHEUS_TOKEN:-}" ] && [ "$MORPHEUS_TOKEN" != "null" ]; then
  log_info "Buscando chave no Cypher via API do Morpheus..."
  API_CONTENT=$(python3 - <<PYEOF
import urllib.request
import urllib.error
import ssl
import json

api_url = "${MORPHEUS_API_URL}".rstrip("/")
token = "${MORPHEUS_TOKEN}"
key = "${CYPHER_TFVARS_KEY}".lstrip("/")

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

req = urllib.request.Request(
    f"{api_url}/api/cypher/{key}",
    headers={
        "Authorization": f"BEARER {token}",
        "Content-Type": "application/json"
    }
)
try:
    with urllib.request.urlopen(req, context=ctx) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        val = data.get('cypher', {}).get('item', {}).get('value') or data.get('data') or ''
        print(val)
except Exception:
    pass
PYEOF
  )
  if [ -n "$API_CONTENT" ]; then
    printf '%s\n' "$API_CONTENT" > "$TFVARS_FILE"
  fi
fi

if [ ! -f "$TFVARS_FILE" ] || [ ! -s "$TFVARS_FILE" ]; then
  log_warn "Nenhum manifesto terraform.tfvars encontrado para exclusão."
fi

# 2. Executa a remoção no arquivo temporário
ARGS=(--file "$TFVARS_FILE")
[ -z "$VM_KEY" ] || ARGS+=(--vm-key "$VM_KEY")
[ -z "$VM_NAME" ] || ARGS+=(--vm-name "$VM_NAME")

log_info "Executando remoção no tfvars: bash $REMOVE_VM_SCRIPT ${ARGS[*]}"
bash "$REMOVE_VM_SCRIPT" "${ARGS[@]}"

# 3. Persiste o conteúdo atualizado de volta no Morpheus Cypher
if [ -n "${MORPHEUS_API_URL:-}" ] && [ -n "${MORPHEUS_TOKEN:-}" ] && [ "$MORPHEUS_TOKEN" != "null" ] && [ -f "$TFVARS_FILE" ]; then
  log_info "Sincronizando terraform.tfvars atualizado no Morpheus Cypher ($CYPHER_TFVARS_KEY)..."
  python3 - <<PYEOF
import urllib.request
import urllib.error
import ssl
import json

api_url = "${MORPHEUS_API_URL}".rstrip("/")
token = "${MORPHEUS_TOKEN}"
key = "${CYPHER_TFVARS_KEY}".lstrip("/")

with open("${TFVARS_FILE}", "r") as f:
    content = f.read()

payload = json.dumps({"value": content, "ttl": 0}).encode("utf-8")

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

req = urllib.request.Request(
    f"{api_url}/api/cypher/{key}",
    data=payload,
    headers={
        "Authorization": f"BEARER {token}",
        "Content-Type": "application/json"
    },
    method="POST"
)

try:
    with urllib.request.urlopen(req, context=ctx) as resp:
        print(f"[INFO] Cypher atualizado com sucesso (HTTP {resp.status})")
except urllib.error.HTTPError as e:
    req.method = "PUT"
    try:
        with urllib.request.urlopen(req, context=ctx) as resp:
            print(f"[INFO] Cypher atualizado via PUT (HTTP {resp.status})")
    except Exception as ex:
        print(f"[WARN] Nao foi possivel atualizar o Cypher via API: {ex}")
except Exception as ex:
    print(f"[WARN] Falha de conexao com API do Morpheus Cypher: {ex}")
PYEOF
fi

# 4. Gera backend_override.tf temporário para GCS
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

# 5. Executa terraform init, validate e apply
log_info "Inicializando Terraform em $POC_DIR..."
"$TERRAFORM_BIN" init -input=false -reconfigure

log_info "Aplicando mudanças no Terraform para desprovisionar recursos na GCP e atualizar o tfstate..."
"$TERRAFORM_BIN" validate
"$TERRAFORM_BIN" apply -auto-approve -input=false

log_info "Desprovisionamento concluído com sucesso. Limpeza automática será executada no término."
