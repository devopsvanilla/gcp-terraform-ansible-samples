#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
DEFAULT_TFVARS_FILE="${REPO_ROOT}/PoCs/vm-nginx-terraform-ansible/terraform.tfvars"

TFVARS_FILE="${DEFAULT_TFVARS_FILE}"
VM_NAME=""

log_info() {
  printf '[INFO] %s\n' "$*"
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
  $(basename "$0") --name <vm_name> [opções]

Descrição:
  Remove do arquivo terraform.tfvars o bloco da VM cujo atributo vm_name
  corresponda exatamente ao valor informado.

Opções obrigatórias:
  --name <valor>                        Valor de vm_name da VM a ser removida

Opções gerais:
  --file <caminho>                      Arquivo terraform.tfvars alvo (padrão: ${DEFAULT_TFVARS_FILE})
  -h, --help                            Exibe esta ajuda

Exemplos:
  $(basename "$0") --name vm-nginx-poc2
  $(basename "$0") --file /tmp/terraform.tfvars --name vm-nginx-poc2
EOF
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1 || die "Dependência obrigatória não encontrada no PATH: ${command_name}"
}

validate_vm_name() {
  local value="$1"
  [[ ${#value} -le 63 ]] || return 1
  [[ "$value" =~ ^[a-z]([-a-z0-9]*[a-z0-9])?$ ]]
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --file)
        [[ $# -ge 2 ]] || die "O argumento --file exige um valor."
        TFVARS_FILE="$2"
        shift 2
        ;;
      --name)
        [[ $# -ge 2 ]] || die "O argumento --name exige um valor."
        VM_NAME="$2"
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
  [[ -n "$VM_NAME" ]] || die "Informe o parâmetro obrigatório --name."
  [[ -f "$TFVARS_FILE" ]] || die "Arquivo terraform.tfvars não encontrado: ${TFVARS_FILE}"
  validate_vm_name "$VM_NAME" || die "--name inválido. Use o padrão de nome de VM da GCE (minúsculas, números e hífen, máx. 63 caracteres)."
}

remove_vm_block() {
  python3 - "$TFVARS_FILE" "$VM_NAME" <<'PY'
import pathlib
import re
import sys

file_path = pathlib.Path(sys.argv[1])
vm_name = sys.argv[2]
lines = file_path.read_text(encoding='utf-8').splitlines(keepends=True)

vms_start = None
vms_end = None
depth = 0
for index, line in enumerate(lines):
    if vms_start is None and line.strip().startswith('vms = {'):
        vms_start = index
        depth = line.count('{') - line.count('}')
        continue
    if vms_start is not None:
        depth += line.count('{') - line.count('}')
        if depth == 0:
            vms_end = index
            break

if vms_start is None or vms_end is None:
    print(f"[ERROR] Não foi possível localizar o bloco 'vms = {{ ... }}' em {file_path}.", file=sys.stderr)
    raise SystemExit(1)

entry_starts = []
inside_entry = False
entry_start = None
entry_depth = 0
for index in range(vms_start + 1, vms_end):
    stripped = lines[index].strip()
    if not inside_entry and re.match(r'^[A-Za-z][A-Za-z0-9_]*\s*=\s*\{$', stripped):
        inside_entry = True
        entry_start = index
        entry_depth = lines[index].count('{') - lines[index].count('}')
        continue
    if inside_entry:
        entry_depth += lines[index].count('{') - lines[index].count('}')
        if entry_depth == 0:
            entry_starts.append((entry_start, index))
            inside_entry = False
            entry_start = None

matches = []
for start, end in entry_starts:
    block_text = ''.join(lines[start:end + 1])
    if re.search(rf'^\s*vm_name\s*=\s*"{re.escape(vm_name)}"\s*$', block_text, flags=re.MULTILINE):
        matches.append((start, end))

if not matches:
    print(f"[ERROR] Nenhuma VM com vm_name = '{vm_name}' foi encontrada em {file_path}.", file=sys.stderr)
    raise SystemExit(1)

if len(matches) > 1:
    print(f"[ERROR] Foram encontrados múltiplos blocos com vm_name = '{vm_name}' em {file_path}. Corrija manualmente para evitar remoção ambígua.", file=sys.stderr)
    raise SystemExit(1)

start, end = matches[0]
while start > vms_start + 1 and lines[start - 1].strip() == '':
    start -= 1

del lines[start:end + 1]
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

  local backup_file
  backup_file="$(mktemp)"
  cp -- "$TFVARS_FILE" "$backup_file"

  log_info "Removendo VM '${VM_NAME}' do arquivo ${TFVARS_FILE}"
  if ! remove_vm_block; then
    rm -f -- "$backup_file"
    die "Falha ao remover o bloco da VM '${VM_NAME}'."
  fi

  if ! run_terraform_checks; then
    cp -- "$backup_file" "$TFVARS_FILE"
    rm -f -- "$backup_file"
    die "A exclusão da VM falhou na validação; o arquivo original foi restaurado."
  fi

  rm -f -- "$backup_file"
  log_info "VM '${VM_NAME}' removida com sucesso de ${TFVARS_FILE}."
}

main "$@"
