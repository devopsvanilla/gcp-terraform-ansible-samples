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

# Injeção de credenciais GCP, chaves do Cypher e contexto de API Morpheus
GCP_CREDS_SECRET='<%=cypher.read("secret/gcp-terraform-ansible-samples")%>'
CYPHER_TFVARS_VALUE='<%=cypher.read("secret/tfvars-gcp-create-vm-gcstate")%>'
MORPHEUS_API_URL='<%=morpheus.apiUrl%>'
MORPHEUS_TOKEN='<%=morpheus.apiAccessToken%>'
CYPHER_TFVARS_KEY="secret/tfvars-gcp-create-vm-gcstate"

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
ADD_VM_SCRIPT="${ADD_VM_SCRIPT:-$REPO_DIR/scripts/add-vm-to-tfvars.sh}"
REMOVE_VM_SCRIPT="${REMOVE_VM_SCRIPT:-$REPO_DIR/scripts/remove-vm-from-tfvars.sh}"
TFVARS_FILE="$POC_DIR/terraform.tfvars"
TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"
TFSTATE_BUCKET="${TFSTATE_BUCKET:-tfstate-devopsvanilla-samples}"
TFSTATE_PREFIX="${TFSTATE_PREFIX:-gcp-create-vm-gcstate}"

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
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

[ -d "$REPO_DIR" ] || { log_error "Repositório não encontrado em $REPO_DIR"; exit 1; }
[ -f "$ADD_VM_SCRIPT" ] || { log_error "Script não encontrado em $ADD_VM_SCRIPT"; exit 1; }
chmod +x "$ADD_VM_SCRIPT" 2>/dev/null || true

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

# Se o arquivo ainda não existir ou estiver vazio, gera a estrutura inicial padrão
if [ ! -f "$TFVARS_FILE" ] || [ ! -s "$TFVARS_FILE" ]; then
  log_info "Inicializando terraform.tfvars base (project_id: $FINAL_PROJECT_ID)..."
  cat <<EOF > "$TFVARS_FILE"
poc_name                         = "gcp-create-vm-gcstate"
project_id                       = "$FINAL_PROJECT_ID"
region                           = "us-central1"
zone                             = "us-central1-a"
manage_vm_external_ip_org_policy = ${MANAGE_ORG_POLICY:-false}
network_name                     = "default"
allowed_http_cidr                = "0.0.0.0/0"
allowed_ssh_cidr                 = "0.0.0.0/0"

vms = {}
EOF
fi

if grep -q "<gcp_project_id>" "$TFVARS_FILE" 2>/dev/null; then
  log_info "Substituindo <gcp_project_id> por '$FINAL_PROJECT_ID' em $TFVARS_FILE..."
  sed -i "s|<gcp_project_id>|$FINAL_PROJECT_ID|g" "$TFVARS_FILE"
fi

if [ "$MANAGE_ORG_POLICY" = "false" ]; then
  sed -i 's/manage_vm_external_ip_org_policy\s*=\s*true/manage_vm_external_ip_org_policy = false/g' "$TFVARS_FILE" 2>/dev/null || true
fi

ARGS=(--file "$TFVARS_FILE" --vm-key "$VM_KEY" --vm-name "$VM_NAME" --overwrite)
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

log_info "Executando: bash $ADD_VM_SCRIPT ${ARGS[*]}"
bash "$ADD_VM_SCRIPT" "${ARGS[@]}"

# 2. Persiste o novo conteúdo atualizado de volta no Morpheus Cypher
if [ -n "${MORPHEUS_API_URL:-}" ] && [ -n "${MORPHEUS_TOKEN:-}" ] && [ "$MORPHEUS_TOKEN" != "null" ]; then
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

# 3. Gera arquivo temporário backend_override.tf para o GCS
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

# 4. Inicializa, valida e aplica o Terraform
log_info "Inicializando Terraform em $POC_DIR..."
"$TERRAFORM_BIN" init -input=false -reconfigure

log_info "Validando e aplicando o manifesto Terraform em $POC_DIR..."
"$TERRAFORM_BIN" validate
"$TERRAFORM_BIN" apply -auto-approve -input=false

log_info "Apply concluído com sucesso. Limpeza automática será executada no término."
