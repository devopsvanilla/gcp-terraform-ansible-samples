#!/usr/bin/env bash
# Shell Script executado pelo Morpheus Data a partir do repositório Git.
# As opções customizadas preenchidas no formulário do Morpheus são passadas
# automaticamente como variáveis de ambiente pelo Morpheus Data.
set -euo pipefail

SCRIPT_SOURCE="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_SOURCE")" && pwd)"

if [[ -z "${REPO_DIR:-}" ]]; then
  if [[ -d "$SCRIPT_DIR/PoCs/vm-nginx-terraform-ansible" ]]; then
    REPO_DIR="$SCRIPT_DIR"
  elif [[ -d "$SCRIPT_DIR/../../PoCs/vm-nginx-terraform-ansible" ]]; then
    REPO_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
  elif [[ -d "$SCRIPT_DIR/../../../PoCs/vm-nginx-terraform-ansible" ]]; then
    REPO_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
  elif [[ -d "$PWD/PoCs/vm-nginx-terraform-ansible" ]]; then
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

# Lê as opções injetadas pelo Morpheus via variáveis de ambiente e/ou JSON payload
if command -v python3 >/dev/null 2>&1; then
  eval "$(python3 - << 'PY'
import json, os, re, sys

env = dict(os.environ)
custom_opts = {}

# Parse JSON strings em qualquer variável de ambiente (ex.: MORPHEUS_CUSTOM_OPTIONS, customOptions, morpheus, etc.)
for k, v in env.items():
    v_str = str(v).strip()
    if (v_str.startswith('{') and v_str.endswith('}')) or (v_str.startswith('[') and v_str.endswith(']')):
        try:
            parsed = json.loads(v_str)
            if isinstance(parsed, dict):
                if 'customOptions' in parsed and isinstance(parsed['customOptions'], dict):
                    custom_opts.update(parsed['customOptions'])
                elif 'custom_options' in parsed and isinstance(parsed['custom_options'], dict):
                    custom_opts.update(parsed['custom_options'])
                else:
                    custom_opts.update(parsed)
        except Exception:
            pass

# Procura também arquivos de payload JSON no diretório atual ou /tmp
for path in ['.', '/tmp']:
    if os.path.isdir(path):
        try:
            for f in os.listdir(path):
                if f.endswith('.json') and any(tag in f.lower() for tag in ['morpheus', 'payload', 'task', 'custom', 'spec']):
                    try:
                        with open(os.path.join(path, f), 'r', encoding='utf-8') as jf:
                            parsed = json.load(jf)
                            if isinstance(parsed, dict):
                                if 'customOptions' in parsed and isinstance(parsed['customOptions'], dict):
                                    custom_opts.update(parsed['customOptions'])
                                elif 'custom_options' in parsed and isinstance(parsed['custom_options'], dict):
                                    custom_opts.update(parsed['custom_options'])
                                else:
                                    custom_opts.update(parsed)
                    except Exception:
                        pass
        except Exception:
            pass

def get_val(*names):
    target_cleaned = [re.sub(r'[^a-z0-9]', '', n.lower()) for n in names if n]
    for k, v in custom_opts.items():
        k_clean = re.sub(r'[^a-z0-9]', '', str(k).lower())
        for t in target_cleaned:
            if k_clean == t or k_clean.endswith(t) or k_clean == f"morpheuscustomoptions{t}":
                if v is not None and str(v).strip() != '' and str(v).lower() != 'null':
                    return str(v).strip()
    for k, v in env.items():
        k_clean = re.sub(r'[^a-z0-9]', '', str(k).lower())
        for t in target_cleaned:
            if k_clean == t or k_clean == f"customoptions{t}" or k_clean == f"morpheuscustomoptions{t}" or k_clean == f"morpheus{t}" or k_clean.endswith(t):
                if v is not None and str(v).strip() != '' and str(v).lower() != 'null':
                    return str(v).strip()
    return ""

def q(s):
    return json.dumps(s)

print(f"VM_KEY={q(get_val('vmKey', 'vm_key', 'vm-nginx-vm-key', 'key'))}")
print(f"VM_NAME={q(get_val('vmName', 'vm_name', 'vm-nginx-vm-name', 'name'))}")
print(f"MACHINE_TYPE_OVERRIDE={q(get_val('machineTypeOverride', 'machine_type_override', 'vm-nginx-machine-type-override'))}")
print(f"MACHINE_SERIES={q(get_val('machineSeries', 'machine_series', 'vm-nginx-machine-series'))}")
print(f"VCPU_COUNT={q(get_val('vcpuCount', 'vcpu_count', 'vm-nginx-vcpu-count'))}")
print(f"MEMORY_GB={q(get_val('memoryGb', 'memory_gb', 'vm-nginx-memory-gb'))}")
print(f"DISK_TYPE={q(get_val('diskType', 'disk_type', 'vm-nginx-disk-type'))}")
print(f"DISK_SIZE_GB={q(get_val('diskSizeGb', 'disk_size_gb', 'vm-nginx-disk-size-gb'))}")
print(f"BOOT_IMAGE_PROJECT={q(get_val('bootImageProject', 'boot_image_project', 'vm-nginx-boot-image-project'))}")
print(f"BOOT_IMAGE_FAMILY={q(get_val('bootImageFamily', 'boot_image_family', 'vm-nginx-boot-image-family'))}")
print(f"ASSIGN_EXTERNAL_IP={q(get_val('assignExternalIp', 'assign_external_ip', 'vm-nginx-assign-external-ip'))}")
print(f"SSH_USERNAME={q(get_val('sshUsername', 'ssh_username', 'vm-nginx-ssh-username'))}")
print(f"SSH_PUBLIC_KEY={q(get_val('sshPublicKey', 'ssh_public_key', 'vm-nginx-ssh-public-key'))}")
print(f"NETWORK_NAME={q(get_val('networkName', 'network_name', 'vm-nginx-network-name'))}")
print(f"SUBNETWORK_NAME={q(get_val('subnetworkName', 'subnetwork_name', 'vm-nginx-subnetwork-name'))}")
print(f"ALLOWED_HTTP_CIDR={q(get_val('allowedHttpCidr', 'allowed_http_cidr', 'vm-nginx-allowed-http-cidr'))}")
print(f"ALLOWED_SSH_CIDR={q(get_val('allowedSshCidr', 'allowed_ssh_cidr', 'vm-nginx-allowed-ssh-cidr'))}")
print(f"MANAGE_ORG_POLICY={q(get_val('manageVmExternalIpOrgPolicy', 'manage_vm_external_ip_org_policy', 'manageOrgPolicy', 'vm-nginx-manage-org-policy'))}")
print(f"USER_GROUPS={q(get_val('userGroups', 'user_groups', 'vm-nginx-user-groups'))}")
PY
)"
else
  VM_KEY="${vmKey:-${VM_KEY:-${MORPHEUS_CUSTOM_OPTIONS_VMKEY:-${vm_key:-}}}}"
  VM_NAME="${vmName:-${VM_NAME:-${MORPHEUS_CUSTOM_OPTIONS_VMNAME:-${vm_name:-}}}}"
  MACHINE_TYPE_OVERRIDE="${machineTypeOverride:-${MACHINE_TYPE_OVERRIDE:-${machine_type_override:-}}}"
  MACHINE_SERIES="${machineSeries:-${MACHINE_SERIES:-${machine_series:-}}}"
  VCPU_COUNT="${vcpuCount:-${VCPU_COUNT:-${vcpu_count:-}}}"
  MEMORY_GB="${memoryGb:-${MEMORY_GB:-${memory_gb:-}}}"
  DISK_TYPE="${diskType:-${DISK_TYPE:-${disk_type:-}}}"
  DISK_SIZE_GB="${diskSizeGb:-${DISK_SIZE_GB:-${disk_size_gb:-}}}"
  BOOT_IMAGE_PROJECT="${bootImageProject:-${BOOT_IMAGE_PROJECT:-${boot_image_project:-}}}"
  BOOT_IMAGE_FAMILY="${bootImageFamily:-${BOOT_IMAGE_FAMILY:-${boot_image_family:-}}}"
  ASSIGN_EXTERNAL_IP="${assignExternalIp:-${ASSIGN_EXTERNAL_IP:-${assign_external_ip:-}}}"
  SSH_USERNAME="${sshUsername:-${SSH_USERNAME:-${ssh_username:-}}}"
  SSH_PUBLIC_KEY="${sshPublicKey:-${SSH_PUBLIC_KEY:-${ssh_public_key:-}}}"
  NETWORK_NAME="${networkName:-${NETWORK_NAME:-${network_name:-}}}"
  SUBNETWORK_NAME="${subnetworkName:-${SUBNETWORK_NAME:-${subnetwork_name:-}}}"
  ALLOWED_HTTP_CIDR="${allowedHttpCidr:-${ALLOWED_HTTP_CIDR:-${allowed_http_cidr:-}}}"
  ALLOWED_SSH_CIDR="${allowedSshCidr:-${ALLOWED_SSH_CIDR:-${allowed_ssh_cidr:-}}}"
  MANAGE_ORG_POLICY="${manageVmExternalIpOrgPolicy:-${MANAGE_VM_EXTERNAL_IP_ORG_POLICY:-${manage_vm_external_ip_org_policy:-}}}"
  USER_GROUPS="${userGroups:-${USER_GROUPS:-${user_groups:-}}}"
fi

# Fallbacks automáticos para vmKey / vmName
if [[ -z "$VM_KEY" && -n "$VM_NAME" ]]; then
  VM_KEY="$(echo "$VM_NAME" | tr '-' '_' | tr -cd 'a-zA-Z0-9_')"
  log_info "vmKey preenchido automaticamente a partir de vmName: $VM_KEY"
fi

if [[ -z "$VM_NAME" && -n "$VM_KEY" ]]; then
  VM_NAME="$(echo "$VM_KEY" | tr '_' '-')"
  log_info "vmName preenchido automaticamente a partir de vmKey: $VM_NAME"
fi

if [[ -z "$VM_KEY" || -z "$VM_NAME" ]]; then
  log_error "Parâmetros obrigatórios ausentes. VM_KEY='$VM_KEY', VM_NAME='$VM_NAME'."
  log_info "Variáveis de ambiente disponíveis no processo:"
  env | grep -v -i -E 'pass|secret|token|key' | sort || true
  exit 1
fi

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
  if [[ -f "$REPO_DIR/scripts/gcp-key.json" ]]; then
    log_info "Carregando GOOGLE_CREDENTIALS a partir de $REPO_DIR/scripts/gcp-key.json..."
    export GOOGLE_CREDENTIALS="$(cat "$REPO_DIR/scripts/gcp-key.json")"
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
