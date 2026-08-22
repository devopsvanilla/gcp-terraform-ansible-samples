#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_TFVARS_FILE="${REPO_ROOT}/PoCs/gcp-create-vm-gcstate/terraform.tfvars"
UNSET="__COPILOT_UNSET__"

TFVARS_FILE="${DEFAULT_TFVARS_FILE}"
VM_KEY="${UNSET}"
VM_NAME="${UNSET}"
SKIP_VALIDATE="false"
DRY_RUN="false"

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
  $(basename "$0") [--vm-key <chave_logica> | --vm-name <nome_vm>] [opções]

Descrição:
  Remove uma entrada de VM do mapa vms no arquivo terraform.tfvars,
  executa terraform fmt e terraform validate ao final.

Opções de identificação (ao menos uma obrigatória):
  --vm-key <valor>                      Chave lógica da VM no mapa vms (ex.: vm_nginx_poc2)
  --vm-name <valor>                     Nome real da VM no GCP (ex.: vm-nginx-poc2)

Opções gerais:
  --file <caminho>                      Arquivo terraform.tfvars alvo (padrão: ${DEFAULT_TFVARS_FILE})
  --skip-validate, --no-validate        Pula a execução de terraform validate
  --dry-run                             Apenas simula a remoção sem alterar o arquivo
  -h, --help                            Exibe esta ajuda

Exemplo:
  $(basename "$0") --vm-key vm_nginx_poc2
  $(basename "$0") --vm-name loonar-teste-sandro
EOF
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || die "Dependência obrigatória não encontrada no PATH: ${command_name}"
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
      --vm-name|--name)
        [[ $# -ge 2 ]] || die "O argumento $1 exige um valor."
        VM_NAME="$2"
        shift 2
        ;;
      --skip-validate|--no-validate)
        SKIP_VALIDATE="true"
        shift 1
        ;;
      --dry-run)
        DRY_RUN="true"
        shift 1
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
  if [[ "$VM_KEY" == "$UNSET" && "$VM_NAME" == "$UNSET" ]]; then
    die "Informe ao menos um parâmetro de identificação: --vm-key ou --vm-name."
  fi

  if [[ ! -f "$TFVARS_FILE" ]]; then
    log_warn "Arquivo ${TFVARS_FILE} não existia; criando estrutura base..."
    cat <<'EOF' > "$TFVARS_FILE"
poc_name                         = "gcp-create-vm-gcstate"
project_id                       = "poc-terraform-ansible"
region                           = "us-central1"
zone                             = "us-central1-a"
manage_vm_external_ip_org_policy = false
network_name                     = "default"
allowed_http_cidr                = "0.0.0.0/0"
allowed_ssh_cidr                 = "0.0.0.0/0"

vms = {}
EOF
  fi
}

remove_vm_entry() {
  python3 - "$TFVARS_FILE" "$VM_KEY" "$VM_NAME" "$DRY_RUN" <<'PY'
import pathlib
import re
import sys

file_path = pathlib.Path(sys.argv[1])
vm_key = sys.argv[2]
vm_name = sys.argv[3]
dry_run = (sys.argv[4].lower() == 'true')
unset = '__COPILOT_UNSET__'

if not file_path.exists():
    print(f"[ERROR] Arquivo não encontrado: {file_path}", file=sys.stderr)
    raise SystemExit(1)

text = file_path.read_text(encoding='utf-8')
lines = text.splitlines(keepends=True)

# 1. Localizar o bloco vms = { ... }
vms_start = None
depth = 0
vms_end = None

for idx, line in enumerate(lines):
    if vms_start is None and re.match(r'^\s*vms\s*=\s*\{', line):
        vms_start = idx
        depth = line.count('{') - line.count('}')
        if depth == 0:
            vms_end = idx
            break
        continue
    if vms_start is not None:
        depth += line.count('{') - line.count('}')
        if depth == 0:
            vms_end = idx
            break

if vms_start is None or vms_end is None:
    print(f"[WARN] Bloco 'vms = {{ ... }}' não encontrado em {file_path}.", file=sys.stderr)
    raise SystemExit(0)

# 2. Identificar os blocos de VM individuais dentro de vms = { ... }
vm_blocks = []
current_key = None
current_start = None
current_depth = 0

if vms_start != vms_end:
    for idx in range(vms_start + 1, vms_end):
        line = lines[idx]
        if current_start is None:
            m = re.match(r'^\s*(?:["\']?([a-zA-Z0-9_-]+)["\']?)\s*=\s*\{', line)
            if m:
                current_key = m.group(1)
                current_start = idx
                current_depth = line.count('{') - line.count('}')
                continue
        else:
            current_depth += line.count('{') - line.count('}')
            if current_depth <= 0:
                block_content = ''.join(lines[current_start:idx+1])
                # Extrair vm_name do bloco se existir
                nm_match = re.search(r'vm_name\s*=\s*["\']([^"\']+)["\']', block_content)
                extracted_name = nm_match.group(1) if nm_match else ""
                vm_blocks.append({
                    'key': current_key,
                    'name': extracted_name,
                    'start': current_start,
                    'end': idx + 1
                })
                current_start = None
                current_key = None

# 3. Encontrar a VM alvo para remoção
target_block = None
for b in vm_blocks:
    if vm_key != unset and b['key'] == vm_key:
        target_block = b
        break
    if vm_name != unset and b['name'] == vm_name:
        target_block = b
        break

if not target_block:
    search_term = vm_key if vm_key != unset else vm_name
    print(f"[WARN] Nenhuma VM encontrada com o identificador '{search_term}' em {file_path}.", file=sys.stderr)
    raise SystemExit(0)

target_start = target_block['start']
target_end = target_block['end']

print(f"[INFO] Localizada entrada da VM (chave: '{target_block['key']}', nome: '{target_block['name']}') nas linhas {target_start + 1} a {target_end}.")

if dry_run:
    print(f"[INFO] Modo dry-run: nenhuma alteração gravada.")
    raise SystemExit(0)

new_lines = lines[:target_start] + lines[target_end:]
new_text = ''.join(new_lines)
file_path.write_text(new_text, encoding='utf-8')
print(f"[INFO] VM '{target_block['key']}' removida com sucesso de {file_path}.")
PY
}

run_terraform_checks() {
  local module_dir
  module_dir="$(cd -- "$(dirname -- "$TFVARS_FILE")" && pwd)"
  local tfvars_basename
  tfvars_basename="$(basename -- "$TFVARS_FILE")"

  log_info "Executando terraform fmt em ${tfvars_basename}"
  terraform -chdir="$module_dir" fmt "$tfvars_basename" >/dev/null || true

  if [[ "${SKIP_VALIDATE}" == "true" ]]; then
    log_info "Validação do Terraform ignorada (--skip-validate)."
    return 0
  fi

  log_info "Executando terraform validate em ${module_dir}"
  if ! terraform -chdir="$module_dir" validate >/dev/null 2>&1; then
    log_info "Providers ausentes ou validação pendente; executando terraform init -backend=false..."
    terraform -chdir="$module_dir" init -backend=false -input=false >/dev/null 2>&1 || true
    terraform -chdir="$module_dir" validate >/dev/null
  fi
}

main() {
  require_command python3
  require_command terraform

  parse_args "$@"
  validate_args

  local backup_file
  backup_file="$(mktemp)"
  cp -- "$TFVARS_FILE" "$backup_file"

  remove_vm_entry

  if [[ "$DRY_RUN" == "false" ]]; then
    if ! run_terraform_checks; then
      cp -- "$backup_file" "$TFVARS_FILE"
      rm -f -- "$backup_file"
      die "A remoção da VM falhou na validação; o arquivo original foi restaurado."
    fi
  fi

  rm -f -- "$backup_file"
}

main "$@"
