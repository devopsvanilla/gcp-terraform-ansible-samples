#!/usr/bin/env bash
set -euo pipefail

export GOOGLE_CREDENTIALS='<%=cypher.read("secret/gcp-terraform-ansible-samples")%>'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_TFVARS_FILE="${REPO_ROOT}/PoCs/vm-nginx-terraform-ansible/terraform.tfvars"
UNSET="__COPILOT_UNSET__"

TFVARS_FILE="${DEFAULT_TFVARS_FILE}"
VM_KEY=""
VM_NAME=""
MACHINE_TYPE_OVERRIDE="${UNSET}"
MACHINE_SERIES="${UNSET}"
VCPU_COUNT="${UNSET}"
MEMORY_GB="${UNSET}"
DISK_TYPE="${UNSET}"
DISK_SIZE_GB="${UNSET}"
BOOT_IMAGE_PROJECT="${UNSET}"
BOOT_IMAGE_FAMILY="${UNSET}"
ASSIGN_EXTERNAL_IP="${UNSET}"
SSH_USERNAME="${UNSET}"
SSH_PUBLIC_KEY="${UNSET}"
NETWORK_NAME="${UNSET}"
SUBNETWORK_NAME="${UNSET}"
ALLOWED_HTTP_CIDR="${UNSET}"
ALLOWED_SSH_CIDR="${UNSET}"
MANAGE_VM_EXTERNAL_IP_ORG_POLICY="${UNSET}"
USER_GROUPS_CSV=""

log_info() {
  printf '[INFO] %s\n' "$*"
}

log_warn() {
  printf '[WARN] %s\n' "$*" >&2
}

log_error() {
  printf '[ERROR] %s\n' "$*" >&2
}

die() {
  log_error "$*"
  exit 1
}

usage() {
  cat <<EOF
Uso:
  $(basename "$0") --vm-key <chave_logica> --vm-name <nome_vm> [opções]

Descrição:
  Adiciona uma nova entrada ao mapa vms em um arquivo terraform.tfvars,
  valida parâmetros obrigatórios/opcionais, impede duplicidade de vm_name
  e executa terraform fmt + terraform validate ao final.

Opções obrigatórias:
  --vm-key <valor>                      Chave lógica da VM no mapa vms (ex.: vm_nginx_poc2)
  --vm-name <valor>                     Nome real da VM no GCP (ex.: vm-nginx-poc2)

Opções gerais:
  --file <caminho>                      Arquivo terraform.tfvars alvo (padrão: ${DEFAULT_TFVARS_FILE})
  -h, --help                            Exibe esta ajuda

Opções adicionais por VM:
  --machine-type-override <valor>
  --machine-series <valor>
  --vcpu-count <inteiro>
  --memory-gb <inteiro>
  --disk-type <valor>
  --disk-size-gb <inteiro>
  --boot-image-project <valor>
  --boot-image-family <valor>
  --assign-external-ip <true|false>
  --ssh-username <valor>
  --ssh-public-key <valor>
  --network-name <valor>
  --subnetwork-name <valor>
  --allowed-http-cidr <CIDR>
  --allowed-ssh-cidr <CIDR>
  --manage-vm-external-ip-org-policy <true|false>
  --user-group <grupo>                  Pode ser informado múltiplas vezes
  --user-groups <g1,g2,...>             Lista separada por vírgulas

Exemplo:
  $(basename "$0") \
    --vm-key vm_nginx_poc2 \
    --vm-name vm-nginx-poc2 \
    --machine-type-override e2-micro \
    --machine-series e2 \
    --vcpu-count 1 \
    --memory-gb 1 \
    --disk-type pd-standard \
    --disk-size-gb 30 \
    --boot-image-project debian-cloud \
    --boot-image-family debian-12 \
    --assign-external-ip true \
    --ssh-username devopsvanilla \
    --ssh-public-key 'ssh-rsa AAAA... devopsvanilla@host' \
    --network-name default \
    --subnetwork-name '' \
    --allowed-http-cidr 0.0.0.0/0 \
    --allowed-ssh-cidr 198.51.100.25/32 \
    --user-group sudo \
    --user-group www-data
EOF
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || die "Dependência obrigatória não encontrada no PATH: ${command_name}"
}

is_true_or_false() {
  local value="$1"
  [[ "$value" == "true" || "$value" == "false" ]]
}

is_positive_integer() {
  local value="$1"
  [[ "$value" =~ ^[1-9][0-9]*$ ]]
}

validate_cidr() {
  local value="$1"
  python3 - "$value" <<'PY'
import ipaddress
import sys

try:
    ipaddress.ip_network(sys.argv[1], strict=False)
except ValueError:
    raise SystemExit(1)
PY
}

validate_vm_key() {
  local value="$1"
  [[ "$value" =~ ^[a-zA-Z][a-zA-Z0-9_]*$ ]]
}

validate_vm_name() {
  local value="$1"
  [[ ${#value} -le 63 ]] || return 1
  [[ "$value" =~ ^[a-z]([-a-z0-9]*[a-z0-9])?$ ]]
}

validate_ssh_public_key() {
  local value="$1"
  [[ "$value" =~ ^(ssh-rsa|ssh-ed25519|ecdsa-sha2-nistp256|ecdsa-sha2-nistp384|ecdsa-sha2-nistp521)[[:space:]]+[A-Za-z0-9+/=]+([[:space:]].*)?$ ]]
}

validate_linux_name() {
  local value="$1"
  [[ "$value" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]
}

trim_csv_item() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

hcl_quote() {
  python3 - "$1" <<'PY'
import json
import sys
print(json.dumps(sys.argv[1]))
PY
}

join_user_groups_hcl() {
  local csv="$1"
  python3 - "$csv" <<'PY'
import json
import sys
items = [item.strip() for item in sys.argv[1].split(',') if item.strip()]
print('[' + ', '.join(json.dumps(item) for item in items) + ']')
PY
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --file)
        [[ $# -ge 2 ]] || die "O argumento --file exige um valor."
        TFVARS_FILE="$2"
        shift 2
        ;;
      --vm-key)
        [[ $# -ge 2 ]] || die "O argumento --vm-key exige um valor."
        VM_KEY="$2"
        shift 2
        ;;
      --vm-name)
        [[ $# -ge 2 ]] || die "O argumento --vm-name exige um valor."
        VM_NAME="$2"
        shift 2
        ;;
      --machine-type-override)
        MACHINE_TYPE_OVERRIDE="$2"
        shift 2
        ;;
      --machine-series)
        MACHINE_SERIES="$2"
        shift 2
        ;;
      --vcpu-count)
        VCPU_COUNT="$2"
        shift 2
        ;;
      --memory-gb)
        MEMORY_GB="$2"
        shift 2
        ;;
      --disk-type)
        DISK_TYPE="$2"
        shift 2
        ;;
      --disk-size-gb)
        DISK_SIZE_GB="$2"
        shift 2
        ;;
      --boot-image-project)
        BOOT_IMAGE_PROJECT="$2"
        shift 2
        ;;
      --boot-image-family)
        BOOT_IMAGE_FAMILY="$2"
        shift 2
        ;;
      --assign-external-ip)
        ASSIGN_EXTERNAL_IP="$2"
        shift 2
        ;;
      --ssh-username)
        SSH_USERNAME="$2"
        shift 2
        ;;
      --ssh-public-key)
        SSH_PUBLIC_KEY="$2"
        shift 2
        ;;
      --network-name)
        NETWORK_NAME="$2"
        shift 2
        ;;
      --subnetwork-name)
        SUBNETWORK_NAME="$2"
        shift 2
        ;;
      --allowed-http-cidr)
        ALLOWED_HTTP_CIDR="$2"
        shift 2
        ;;
      --allowed-ssh-cidr)
        ALLOWED_SSH_CIDR="$2"
        shift 2
        ;;
      --manage-vm-external-ip-org-policy)
        MANAGE_VM_EXTERNAL_IP_ORG_POLICY="$2"
        shift 2
        ;;
      --user-group)
        [[ $# -ge 2 ]] || die "O argumento --user-group exige um valor."
        if [[ -n "$USER_GROUPS_CSV" ]]; then
          USER_GROUPS_CSV+=",$2"
        else
          USER_GROUPS_CSV="$2"
        fi
        shift 2
        ;;
      --user-groups)
        [[ $# -ge 2 ]] || die "O argumento --user-groups exige um valor."
        if [[ -n "$USER_GROUPS_CSV" ]]; then
          USER_GROUPS_CSV+=",$2"
        else
          USER_GROUPS_CSV="$2"
        fi
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Argumento desconhecido: $1. Use --help para ver as opções disponíveis."
        ;;
    esac
  done
}

validate_args() {
  [[ -n "$VM_KEY" ]] || die "Informe o parâmetro obrigatório --vm-key."
  [[ -n "$VM_NAME" ]] || die "Informe o parâmetro obrigatório --vm-name."
  [[ -f "$TFVARS_FILE" ]] || die "Arquivo terraform.tfvars não encontrado: ${TFVARS_FILE}"

  validate_vm_key "$VM_KEY" || die "--vm-key inválido. Use apenas letras, números e underscore, começando por letra."
  validate_vm_name "$VM_NAME" || die "--vm-name inválido. Use o padrão de nome de VM da GCE (minúsculas, números e hífen, máx. 63 caracteres)."

  [[ "$MACHINE_SERIES" == "$UNSET" ]] || [[ "$MACHINE_SERIES" =~ ^[a-z0-9-]+$ ]] || die "--machine-series inválido."
  [[ "$VCPU_COUNT" == "$UNSET" ]] || is_positive_integer "$VCPU_COUNT" || die "--vcpu-count deve ser um inteiro positivo."
  [[ "$MEMORY_GB" == "$UNSET" ]] || is_positive_integer "$MEMORY_GB" || die "--memory-gb deve ser um inteiro positivo."
  [[ "$DISK_TYPE" == "$UNSET" ]] || [[ "$DISK_TYPE" =~ ^[a-z0-9-]+$ ]] || die "--disk-type inválido."
  [[ "$DISK_SIZE_GB" == "$UNSET" ]] || is_positive_integer "$DISK_SIZE_GB" || die "--disk-size-gb deve ser um inteiro positivo."
  [[ "$BOOT_IMAGE_PROJECT" == "$UNSET" ]] || [[ -n "$BOOT_IMAGE_PROJECT" ]] || die "--boot-image-project não pode ser vazio."
  [[ "$BOOT_IMAGE_FAMILY" == "$UNSET" ]] || [[ -n "$BOOT_IMAGE_FAMILY" ]] || die "--boot-image-family não pode ser vazio."
  [[ "$ASSIGN_EXTERNAL_IP" == "$UNSET" ]] || is_true_or_false "$ASSIGN_EXTERNAL_IP" || die "--assign-external-ip deve ser true ou false."
  [[ "$SSH_USERNAME" == "$UNSET" ]] || { [[ -n "$SSH_USERNAME" ]] && validate_linux_name "$SSH_USERNAME"; } || die "--ssh-username inválido para um usuário Linux."
  [[ "$SSH_PUBLIC_KEY" == "$UNSET" ]] || { [[ -n "$SSH_PUBLIC_KEY" ]] && validate_ssh_public_key "$SSH_PUBLIC_KEY"; } || die "--ssh-public-key não parece ser uma chave pública OpenSSH válida."
  [[ "$NETWORK_NAME" == "$UNSET" ]] || [[ -n "$NETWORK_NAME" ]] || die "--network-name não pode ser vazio."
  [[ "$ALLOWED_HTTP_CIDR" == "$UNSET" ]] || validate_cidr "$ALLOWED_HTTP_CIDR" || die "--allowed-http-cidr deve ser um CIDR válido."
  [[ "$ALLOWED_SSH_CIDR" == "$UNSET" ]] || validate_cidr "$ALLOWED_SSH_CIDR" || die "--allowed-ssh-cidr deve ser um CIDR válido."
  [[ "$MANAGE_VM_EXTERNAL_IP_ORG_POLICY" == "$UNSET" ]] || is_true_or_false "$MANAGE_VM_EXTERNAL_IP_ORG_POLICY" || die "--manage-vm-external-ip-org-policy deve ser true ou false."

  if [[ -n "$USER_GROUPS_CSV" ]]; then
    local IFS=','
    local raw_group=""
    for raw_group in $USER_GROUPS_CSV; do
      local group_name
      group_name="$(trim_csv_item "$raw_group")"
      [[ -n "$group_name" ]] || die "--user-group/--user-groups contém um grupo vazio."
      validate_linux_name "$group_name" || die "Nome de grupo Linux inválido: ${group_name}"
    done
  fi
}

ensure_unique_vm_identifiers() {
  python3 - "$TFVARS_FILE" "$VM_KEY" "$VM_NAME" <<'PY'
import pathlib
import re
import sys

file_path = pathlib.Path(sys.argv[1])
vm_key = sys.argv[2]
vm_name = sys.argv[3]
text = file_path.read_text(encoding='utf-8')

if re.search(rf'^\s*{re.escape(vm_key)}\s*=\s*{{\s*$', text, flags=re.MULTILINE):
    print(f"[ERROR] A chave lógica '{vm_key}' já existe em {file_path}.", file=sys.stderr)
    raise SystemExit(1)

if re.search(rf'^\s*vm_name\s*=\s*"{re.escape(vm_name)}"\s*$', text, flags=re.MULTILINE):
    print(f"[ERROR] Já existe uma VM com vm_name = '{vm_name}' em {file_path}.", file=sys.stderr)
    raise SystemExit(1)
PY
}

build_vm_block() {
  local vm_block_file="$1"
  {
    printf '  %s = {\n' "$VM_KEY"
    printf '    vm_name = %s\n' "$(hcl_quote "$VM_NAME")"

    [[ "$MACHINE_TYPE_OVERRIDE" == "$UNSET" ]] || printf '    machine_type_override = %s\n' "$(hcl_quote "$MACHINE_TYPE_OVERRIDE")"
    [[ "$MACHINE_SERIES" == "$UNSET" ]] || printf '    machine_series        = %s\n' "$(hcl_quote "$MACHINE_SERIES")"
    [[ "$VCPU_COUNT" == "$UNSET" ]] || printf '    vcpu_count            = %s\n' "$VCPU_COUNT"
    [[ "$MEMORY_GB" == "$UNSET" ]] || printf '    memory_gb             = %s\n' "$MEMORY_GB"
    [[ "$DISK_TYPE" == "$UNSET" ]] || printf '    disk_type             = %s\n' "$(hcl_quote "$DISK_TYPE")"
    [[ "$DISK_SIZE_GB" == "$UNSET" ]] || printf '    disk_size_gb          = %s\n' "$DISK_SIZE_GB"
    [[ "$BOOT_IMAGE_PROJECT" == "$UNSET" ]] || printf '    boot_image_project    = %s\n' "$(hcl_quote "$BOOT_IMAGE_PROJECT")"
    [[ "$BOOT_IMAGE_FAMILY" == "$UNSET" ]] || printf '    boot_image_family     = %s\n' "$(hcl_quote "$BOOT_IMAGE_FAMILY")"
    [[ "$ASSIGN_EXTERNAL_IP" == "$UNSET" ]] || printf '    assign_external_ip    = %s\n' "$ASSIGN_EXTERNAL_IP"
    [[ "$SSH_USERNAME" == "$UNSET" ]] || printf '    ssh_username          = %s\n' "$(hcl_quote "$SSH_USERNAME")"
    [[ "$SSH_PUBLIC_KEY" == "$UNSET" ]] || printf '    ssh_public_key        = %s\n' "$(hcl_quote "$SSH_PUBLIC_KEY")"
    [[ "$NETWORK_NAME" == "$UNSET" ]] || printf '    network_name          = %s\n' "$(hcl_quote "$NETWORK_NAME")"
    [[ "$SUBNETWORK_NAME" == "$UNSET" ]] || printf '    subnetwork_name       = %s\n' "$(hcl_quote "$SUBNETWORK_NAME")"
    [[ "$ALLOWED_HTTP_CIDR" == "$UNSET" ]] || printf '    allowed_http_cidr     = %s\n' "$(hcl_quote "$ALLOWED_HTTP_CIDR")"
    [[ "$ALLOWED_SSH_CIDR" == "$UNSET" ]] || printf '    allowed_ssh_cidr      = %s\n' "$(hcl_quote "$ALLOWED_SSH_CIDR")"
    [[ "$MANAGE_VM_EXTERNAL_IP_ORG_POLICY" == "$UNSET" ]] || printf '    manage_vm_external_ip_org_policy = %s\n' "$MANAGE_VM_EXTERNAL_IP_ORG_POLICY"
    [[ -z "$USER_GROUPS_CSV" ]] || printf '    user_groups           = %s\n' "$(join_user_groups_hcl "$USER_GROUPS_CSV")"
    printf '  }\n'
  } > "$vm_block_file"
}

insert_vm_block() {
  local vm_block_file="$1"
  python3 - "$TFVARS_FILE" "$vm_block_file" <<'PY'
import pathlib
import sys

file_path = pathlib.Path(sys.argv[1])
vm_block_path = pathlib.Path(sys.argv[2])
lines = file_path.read_text(encoding='utf-8').splitlines(keepends=True)
vm_block = vm_block_path.read_text(encoding='utf-8')

start_index = None
depth = 0
end_index = None

for index, line in enumerate(lines):
    if start_index is None and line.strip().startswith('vms = {'):
        start_index = index
        depth = line.count('{') - line.count('}')
        continue

    if start_index is not None:
        depth += line.count('{') - line.count('}')
        if depth == 0:
            end_index = index
            break

if start_index is None or end_index is None:
    print(f"[ERROR] Não foi possível localizar o bloco 'vms = {{ ... }}' em {file_path}.", file=sys.stderr)
    raise SystemExit(1)

prefix = ''
if end_index > start_index + 1 and lines[end_index - 1].strip() != '':
    prefix = '\n'

lines.insert(end_index, prefix + vm_block)
file_path.write_text(''.join(lines), encoding='utf-8')
PY
}

run_terraform_checks() {
  local module_dir
  module_dir="$(cd -- "$(dirname -- "$TFVARS_FILE")" && pwd)"
  local tfvars_basename
  tfvars_basename="$(basename -- "$TFVARS_FILE")"

  log_info "Executando terraform fmt em ${tfvars_basename}"
  terraform -chdir="$module_dir" fmt "$tfvars_basename" >/dev/null

  log_info "Executando terraform validate em ${module_dir}"
  terraform -chdir="$module_dir" validate >/dev/null
}

main() {
  require_command python3
  require_command terraform

  parse_args "$@"
  validate_args
  ensure_unique_vm_identifiers

  local backup_file
  backup_file="$(mktemp)"
  cp -- "$TFVARS_FILE" "$backup_file"

  local vm_block_file
  vm_block_file="$(mktemp)"
  build_vm_block "$vm_block_file"

  log_info "Adicionando VM '${VM_NAME}' ao arquivo ${TFVARS_FILE}"
  insert_vm_block "$vm_block_file"

  if ! run_terraform_checks; then
    cp -- "$backup_file" "$TFVARS_FILE"
    rm -f -- "$backup_file" "$vm_block_file"
    die "A inclusão da VM falhou na validação; o arquivo original foi restaurado."
  fi

  rm -f -- "$backup_file" "$vm_block_file"
  log_info "VM '${VM_NAME}' adicionada com sucesso em ${TFVARS_FILE}."
}

main "$@"
