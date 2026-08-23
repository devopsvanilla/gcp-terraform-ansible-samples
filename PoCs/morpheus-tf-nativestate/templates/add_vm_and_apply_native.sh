#!/usr/bin/env bash
# ==============================================================================
# Script: add_vm_and_apply_native.sh
# Objetivo: Provisionar VM no GCP mantendo o estado (.tfstate) e tfvars 100% no
#           Morpheus Cypher (Native State), repassando fielmente todos os
#           parâmetros dinâmicos do formulário (disco, vCPU, RAM, etc.).
# ==============================================================================
set -euo pipefail

# 1. Captura as variáveis substituídas pelo Morpheus a partir do formulário
VM_NAME='<%=customOptions.vm_name%>'
VM_KEY='<%=customOptions.vm_name%>'
MACHINE_TYPE_OVERRIDE='<%=customOptions.machine_type_override%>'
MACHINE_SERIES='<%=customOptions.machine_series%>'
VCPU_COUNT='<%=customOptions.vcpu_count%>'
MEMORY_GB='<%=customOptions.memory_gb%>'
DISK_TYPE='<%=customOptions.disk_type%>'
DISK_SIZE_GB='<%=customOptions.disk_size_gb%>'
BOOT_IMAGE_PROJECT='<%=customOptions.boot_image_project%>'
BOOT_IMAGE_FAMILY='<%=customOptions.boot_image_family%>'
ASSIGN_EXTERNAL_IP='<%=customOptions.assign_external_ip%>'
SSH_USERNAME='<%=customOptions.ssh_username%>'
SSH_PUBLIC_KEY='<%=customOptions.ssh_public_key%>'
NETWORK_NAME='<%=customOptions.network_name%>'
SUBNETWORK_NAME='<%=customOptions.subnetwork_name%>'
ALLOWED_HTTP_CIDR='<%=customOptions.allowed_http_cidr%>'
ALLOWED_SSH_CIDR='<%=customOptions.allowed_ssh_cidr%>'
USER_GROUPS='<%=customOptions.user_groups%>'

# 2. Injeção de credenciais GCP e segredos do Cypher
GCP_CREDS_SECRET='<%=cypher.read("secret/gcp-terraform-ansible-samples")%>'
CYPHER_TFVARS_VALUE='<%=cypher.read("secret/tfvars-gcp-create-vm-nativestate")%>'
CYPHER_TFSTATE_VALUE='<%=cypher.read("secret/tfstate-gcp-create-vm-nativestate")%>'
CYPHER_MORPHEUS_URL='<%=cypher.read("secret/morpheus-api-url")%>'
CYPHER_MORPHEUS_TOKEN='<%=cypher.read("secret/morpheus-api-token")%>'

CYPHER_TFVARS_KEY="secret/tfvars-gcp-create-vm-nativestate"
CYPHER_TFSTATE_KEY="secret/tfstate-gcp-create-vm-nativestate"

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "${REPO_DIR:-}" ]; then
  if [ -d "$SCRIPT_DIR/PoCs/gcp-create-vm" ]; then
    REPO_DIR="$SCRIPT_DIR"
  elif [ -d "$SCRIPT_DIR/../../PoCs/gcp-create-vm" ]; then
    REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
  elif [ -d "$SCRIPT_DIR/../../../PoCs/gcp-create-vm" ]; then
    REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  elif [ -d "$PWD/PoCs/gcp-create-vm" ]; then
    REPO_DIR="$PWD"
  else
    REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  fi
fi

POC_DIR="${POC_DIR:-$REPO_DIR/PoCs/gcp-create-vm}"
ADD_VM_SCRIPT="${ADD_VM_SCRIPT:-$REPO_DIR/scripts/add-vm-to-tfvars.sh}"
TFVARS_FILE="$POC_DIR/terraform.tfvars"
TFSTATE_FILE="$POC_DIR/terraform.tfstate"
TERRAFORM_BIN="${TERRAFORM_BIN:-terraform}"
CREDS_FILE=""

cleanup() {
  log_info "Executando limpeza de arquivos sensíveis locais..."
  if [ -n "$CREDS_FILE" ] && [ -f "$CREDS_FILE" ]; then
    rm -f "$CREDS_FILE"
  fi
  if [ -f "$TFVARS_FILE" ]; then
    rm -f "$TFVARS_FILE"
  fi
  if [ -f "$TFSTATE_FILE" ]; then
    rm -f "$TFSTATE_FILE"
  fi
  if [ -f "$TFSTATE_FILE.backup" ]; then
    rm -f "$TFSTATE_FILE.backup"
  fi
}
trap cleanup EXIT

# 3. Restaura tfstate anterior do Cypher se existir
if [ -n "${CYPHER_TFSTATE_VALUE:-}" ] && [ "$CYPHER_TFSTATE_VALUE" != "null" ] && [ "$CYPHER_TFSTATE_VALUE" != "<%=cypher.read(\"secret/tfstate-gcp-create-vm-nativestate\")%>" ]; then
  log_info "Restaurando terraform.tfstate a partir do Morpheus Cypher ($CYPHER_TFSTATE_KEY)..."
  printf '%s\n' "$CYPHER_TFSTATE_VALUE" > "$TFSTATE_FILE"
fi

# 4. Restaura tfvars anterior do Cypher ou inicializa
if [ -n "${CYPHER_TFVARS_VALUE:-}" ] && [ "$CYPHER_TFVARS_VALUE" != "null" ] && [ "$CYPHER_TFVARS_VALUE" != "<%=cypher.read(\"secret/tfvars-gcp-create-vm-nativestate\")%>" ]; then
  log_info "Restaurando terraform.tfvars a partir do Morpheus Cypher ($CYPHER_TFVARS_KEY)..."
  printf '%s\n' "$CYPHER_TFVARS_VALUE" > "$TFVARS_FILE"
else
  log_info "Inicializando novo arquivo terraform.tfvars..."
  touch "$TFVARS_FILE"
fi

# 5. Configura credenciais GCP
if [ -n "${GCP_CREDS_SECRET:-}" ] && [ "$GCP_CREDS_SECRET" != "null" ] && [ "$GCP_CREDS_SECRET" != "<%=cypher.read(\"secret/gcp-terraform-ansible-samples\")%>" ]; then
  CREDS_FILE="$(mktemp -t gcp-creds-XXXXXX.json)"
  printf '%s' "$GCP_CREDS_SECRET" > "$CREDS_FILE"
  export GOOGLE_APPLICATION_CREDENTIALS="$CREDS_FILE"
fi

# 6. Prepara e executa script auxiliar para adicionar VM
[ -n "$VM_NAME" ] && [ "$VM_NAME" != "null" ] || VM_NAME="vm-gcp-poc"
[ -n "$VM_KEY" ] && [ "$VM_KEY" != "null" ] || VM_KEY="$VM_NAME"

ARGS=(--file "$TFVARS_FILE" --vm-key "$VM_KEY" --vm-name "$VM_NAME" --overwrite)
[ -z "$MACHINE_TYPE_OVERRIDE" ] || [ "$MACHINE_TYPE_OVERRIDE" = "null" ] || ARGS+=(--machine-type-override "$MACHINE_TYPE_OVERRIDE")
[ -z "$MACHINE_SERIES" ] || [ "$MACHINE_SERIES" = "null" ] || ARGS+=(--machine-series "$MACHINE_SERIES")
[ -z "$VCPU_COUNT" ] || [ "$VCPU_COUNT" = "null" ] || ARGS+=(--vcpu-count "$VCPU_COUNT")
[ -z "$MEMORY_GB" ] || [ "$MEMORY_GB" = "null" ] || ARGS+=(--memory-gb "$MEMORY_GB")
[ -z "$DISK_TYPE" ] || [ "$DISK_TYPE" = "null" ] || ARGS+=(--disk-type "$DISK_TYPE")
[ -z "$DISK_SIZE_GB" ] || [ "$DISK_SIZE_GB" = "null" ] || ARGS+=(--disk-size-gb "$DISK_SIZE_GB")
[ -z "$BOOT_IMAGE_PROJECT" ] || [ "$BOOT_IMAGE_PROJECT" = "null" ] || ARGS+=(--boot-image-project "$BOOT_IMAGE_PROJECT")
[ -z "$BOOT_IMAGE_FAMILY" ] || [ "$BOOT_IMAGE_FAMILY" = "null" ] || ARGS+=(--boot-image-family "$BOOT_IMAGE_FAMILY")
[ -z "$ASSIGN_EXTERNAL_IP" ] || [ "$ASSIGN_EXTERNAL_IP" = "null" ] || ARGS+=(--assign-external-ip "$ASSIGN_EXTERNAL_IP")
[ -z "$SSH_USERNAME" ] || [ "$SSH_USERNAME" = "null" ] || ARGS+=(--ssh-username "$SSH_USERNAME")
[ -z "$SSH_PUBLIC_KEY" ] || [ "$SSH_PUBLIC_KEY" = "null" ] || ARGS+=(--ssh-public-key "$SSH_PUBLIC_KEY")
[ -z "$NETWORK_NAME" ] || [ "$NETWORK_NAME" = "null" ] || ARGS+=(--network-name "$NETWORK_NAME")
[ -z "$SUBNETWORK_NAME" ] || [ "$SUBNETWORK_NAME" = "null" ] || ARGS+=(--subnetwork-name "$SUBNETWORK_NAME")
[ -z "$ALLOWED_HTTP_CIDR" ] || [ "$ALLOWED_HTTP_CIDR" = "null" ] || ARGS+=(--allowed-http-cidr "$ALLOWED_HTTP_CIDR")
[ -z "$ALLOWED_SSH_CIDR" ] || [ "$ALLOWED_SSH_CIDR" = "null" ] || ARGS+=(--allowed-ssh-cidr "$ALLOWED_SSH_CIDR")

if [ -n "$USER_GROUPS" ] && [ "$USER_GROUPS" != "null" ]; then
  IFS=',' read -ra RAW_GROUPS <<< "$USER_GROUPS"
  for raw_group in "${RAW_GROUPS[@]}"; do
    group_name="$(echo "$raw_group" | xargs)"
    [ -z "$group_name" ] || ARGS+=(--user-group "$group_name")
  done
fi

log_info "Executando add-vm-to-tfvars: bash $ADD_VM_SCRIPT ${ARGS[*]}"
bash "$ADD_VM_SCRIPT" "${ARGS[@]}"

# 7. Executa Terraform Apply
log_info "Inicializando Terraform em $POC_DIR..."
cd "$POC_DIR"
"$TERRAFORM_BIN" init -input=false

log_info "Validando e aplicando o manifesto Terraform..."
"$TERRAFORM_BIN" validate
"$TERRAFORM_BIN" apply -auto-approve -input=false

# 8. Sincroniza o estado e variáveis de volta para o Morpheus Cypher
if [ -n "${CYPHER_MORPHEUS_URL:-}" ] && [ -n "${CYPHER_MORPHEUS_TOKEN:-}" ] && [ "$CYPHER_MORPHEUS_TOKEN" != "null" ]; then
  log_info "Sincronizando tfstate e tfvars atualizados no Morpheus Cypher..."
  python3 - <<PYEOF
import urllib.request
import urllib.error
import ssl
import json
import os

api_url = "${CYPHER_MORPHEUS_URL}".rstrip("/")
token = "${CYPHER_MORPHEUS_TOKEN}"

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

def save_to_cypher(key, filepath):
    if not os.path.exists(filepath):
        return
    with open(filepath, "r") as f:
        content = f.read()
    payload = json.dumps({"value": content, "ttl": 0}).encode("utf-8")
    req = urllib.request.Request(
        f"{api_url}/api/cypher/{key}",
        data=payload,
        headers={"Authorization": f"BEARER {token}", "Content-Type": "application/json"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, context=ctx) as resp:
            print(f"[INFO] Cypher {key} atualizado com sucesso (HTTP {resp.status})")
    except urllib.error.HTTPError as e:
        req.method = "PUT"
        try:
            with urllib.request.urlopen(req, context=ctx) as resp:
                print(f"[INFO] Cypher {key} atualizado via PUT (HTTP {resp.status})")
        except Exception as ex:
            print(f"[WARN] Nao foi possivel atualizar Cypher {key}: {ex}")
    except Exception as ex:
        print(f"[WARN] Erro ao conectar no Morpheus Cypher para {key}: {ex}")

save_to_cypher("${CYPHER_TFVARS_KEY}".lstrip("/"), "${TFVARS_FILE}")
save_to_cypher("${CYPHER_TFSTATE_KEY}".lstrip("/"), "${TFSTATE_FILE}")
PYEOF
fi

log_info "Provisionamento concluído com sucesso e estado salvo no Cypher!"
