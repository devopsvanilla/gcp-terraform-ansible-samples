#!/usr/bin/env bash
# ==============================================================================
# Script: remove_vm_and_apply_native.sh
# Objetivo: Desprovisionar VM no GCP mantendo o estado (.tfstate) no Cypher.
# ==============================================================================
set -euo pipefail

VM_NAME='<%=customOptions.vm_name%>'
VM_KEY='<%=customOptions.vm_name%>'

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
REMOVE_VM_SCRIPT="${REMOVE_VM_SCRIPT:-$REPO_DIR/scripts/remove-vm-from-tfvars.sh}"
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
}
trap cleanup EXIT

# Restaura tfstate e tfvars do Cypher
if [ -n "${CYPHER_TFSTATE_VALUE:-}" ] && [ "$CYPHER_TFSTATE_VALUE" != "null" ] && [ "$CYPHER_TFSTATE_VALUE" != "<%=cypher.read(\"secret/tfstate-gcp-create-vm-nativestate\")%>" ]; then
  printf '%s\n' "$CYPHER_TFSTATE_VALUE" > "$TFSTATE_FILE"
fi
if [ -n "${CYPHER_TFVARS_VALUE:-}" ] && [ "$CYPHER_TFVARS_VALUE" != "null" ] && [ "$CYPHER_TFVARS_VALUE" != "<%=cypher.read(\"secret/tfvars-gcp-create-vm-nativestate\")%>" ]; then
  printf '%s\n' "$CYPHER_TFVARS_VALUE" > "$TFVARS_FILE"
fi

# Configura credenciais GCP
if [ -n "${GCP_CREDS_SECRET:-}" ] && [ "$GCP_CREDS_SECRET" != "null" ] && [ "$GCP_CREDS_SECRET" != "<%=cypher.read(\"secret/gcp-terraform-ansible-samples\")%>" ]; then
  CREDS_FILE="$(mktemp -t gcp-creds-XXXXXX.json)"
  printf '%s' "$GCP_CREDS_SECRET" > "$CREDS_FILE"
  export GOOGLE_APPLICATION_CREDENTIALS="$CREDS_FILE"
fi

if [ -f "$TFVARS_FILE" ] && [ -n "$VM_NAME" ]; then
  log_info "Removendo VM $VM_NAME do terraform.tfvars..."
  bash "$REMOVE_VM_SCRIPT" --file "$TFVARS_FILE" --vm-name "$VM_NAME"
fi

# Executa Terraform Apply para destruir os recursos removidos
cd "$POC_DIR"
"$TERRAFORM_BIN" init -input=false
"$TERRAFORM_BIN" apply -auto-approve -input=false

# Atualiza Cypher
if [ -n "${CYPHER_MORPHEUS_URL:-}" ] && [ -n "${CYPHER_MORPHEUS_TOKEN:-}" ] && [ "$CYPHER_MORPHEUS_TOKEN" != "null" ]; then
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
            print(f"[INFO] Cypher {key} atualizado (HTTP {resp.status})")
    except urllib.error.HTTPError as e:
        req.method = "PUT"
        try:
            with urllib.request.urlopen(req, context=ctx) as resp:
                print(f"[INFO] Cypher {key} atualizado via PUT")
        except Exception:
            pass
    except Exception:
        pass

save_to_cypher("${CYPHER_TFVARS_KEY}".lstrip("/"), "${TFVARS_FILE}")
save_to_cypher("${CYPHER_TFSTATE_KEY}".lstrip("/"), "${TFSTATE_FILE}")
PYEOF
fi

log_info "VM removida com sucesso e estado do Cypher atualizado!"
