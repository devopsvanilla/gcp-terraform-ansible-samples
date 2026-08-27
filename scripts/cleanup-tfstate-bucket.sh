#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: cleanup-tfstate-bucket.sh
# Descrição: Limpa o estado do Terraform (tfstate) ou exclui o bucket GCS
#            utilizado no backend remoto da solução.
# ==============================================================================

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
DEFAULT_BUCKET_NAME="tfstate-devopsvanilla-samples"
DEFAULT_PREFIX="gcp-create-vm-gcstate"

usage() {
  cat <<EOF
Uso:
  $(basename "$0") --project-id <project-id> [opções]

Descrição:
  Remove os objetos de tfstate (incluindo versões anteriores) do bucket GCS
  e, opcionalmente, remove o próprio bucket.

Opções obrigatórias:
  --project-id <id>             ID do projeto GCP onde o bucket está localizado

Opções gerais:
  --bucket-name <nome>          Nome do bucket GCS (padrão: ${DEFAULT_BUCKET_NAME})
  --prefix <prefixo>            Prefixo do estado a ser limpo (padrão: ${DEFAULT_PREFIX})
                                Use --prefix "" ou --all para limpar todo o bucket.
  --vm, --vm-key <nome>         Limpa apenas o estado de uma VM específica (ex.: loonar-teste-sandro)
  --all                         Limpa todos os objetos e prefixos de dentro do bucket
  --delete-bucket               Exclui o bucket GCS completamente após limpar seu conteúdo
  --dry-run                     Apenas lista os objetos que seriam excluídos, sem apagá-los
  -f, --force                   Executa sem pedir confirmação interativa
  -h, --help                    Exibe esta ajuda

Exemplos:
  # 1. Limpar todas as VMs da PoC gcp-create-vm-gcstate
  $(basename "$0") --project-id poc-terraform-ansible

  # 2. Limpar o estado de uma VM específica
  $(basename "$0") --project-id poc-terraform-ansible --vm loonar-teste-sandro

  # 3. Limpar todo o conteúdo do bucket
  $(basename "$0") --project-id poc-terraform-ansible --all

  # 4. Limpar o conteúdo e excluir o bucket GCS
  $(basename "$0") --project-id poc-terraform-ansible --delete-bucket

  # 5. Simulação (dry-run) de uma VM específica
  $(basename "$0") --project-id poc-terraform-ansible --vm loonar-teste-sandro --dry-run
EOF
}

PROJECT_ID=""
BUCKET_NAME="${DEFAULT_BUCKET_NAME}"
PREFIX="${DEFAULT_PREFIX}"
DELETE_BUCKET="false"
DRY_RUN="false"
FORCE="false"
ALL_PREFIXES="false"

log_info() { printf '[INFO] %s\n' "$*"; }
log_warn() { printf '[WARN] %s\n' "$*" >&2; }
log_error() { printf '[ERROR] %s\n' "$*" >&2; }
die() { log_error "$*"; exit 1; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-id)
      [[ $# -ge 2 ]] || die "O argumento --project-id exige um valor."
      PROJECT_ID="$2"
      shift 2
      ;;
    --bucket-name)
      [[ $# -ge 2 ]] || die "O argumento --bucket-name exige um valor."
      BUCKET_NAME="$2"
      shift 2
      ;;
    --prefix)
      [[ $# -ge 2 ]] || die "O argumento --prefix exige um valor."
      PREFIX="$2"
      shift 2
      ;;
    --vm|--vm-key)
      [[ $# -ge 2 ]] || die "O argumento $1 exige o nome/chave da VM."
      PREFIX="${DEFAULT_PREFIX}/$2"
      shift 2
      ;;
    --all)
      ALL_PREFIXES="true"
      PREFIX=""
      shift 1
      ;;
    --delete-bucket)
      DELETE_BUCKET="true"
      shift 1
      ;;
    --dry-run)
      DRY_RUN="true"
      shift 1
      ;;
    -f|--force)
      FORCE="true"
      shift 1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Argumento inválido: $1. Use --help para ver as opções disponíveis."
      ;;
  esac
done

if [[ -z "${PROJECT_ID}" ]]; then
  DETECTED_PROJ="$(gcloud config get-value project 2>/dev/null || true)"
  if [[ -n "${DETECTED_PROJ}" && "${DETECTED_PROJ}" != "(unset)" ]]; then
    PROJECT_ID="${DETECTED_PROJ}"
    log_info "Project ID detectado automaticamente via gcloud: ${PROJECT_ID}"
  else
    die "O parâmetro --project-id é obrigatório."
  fi
fi

# Valida se a ferramenta gcloud está disponível
command -v gcloud >/dev/null 2>&1 || die "gcloud CLI não encontrado no PATH."

# Verifica se o bucket existe no GCP
log_info "Verificando existência do bucket gs://${BUCKET_NAME} no projeto ${PROJECT_ID}..."
if ! gcloud storage buckets describe "gs://${BUCKET_NAME}" --project="${PROJECT_ID}" >/dev/null 2>&1; then
  log_warn "O bucket gs://${BUCKET_NAME} não existe ou você não tem permissão para acessá-lo."
  exit 0
fi

# Define o caminho alvo no GCS
if [[ -n "${PREFIX}" && "${ALL_PREFIXES}" == "false" ]]; then
  TARGET_URI="gs://${BUCKET_NAME}/${PREFIX}"
else
  TARGET_URI="gs://${BUCKET_NAME}"
fi

# Confirmação do usuário se não for -f / --force e não for --dry-run
if [[ "${FORCE}" == "false" && "${DRY_RUN}" == "false" ]]; then
  echo ""
  log_warn "ATENÇÃO: Você está prestes a apagar dados no Google Cloud Storage!"
  log_warn "  Projeto: ${PROJECT_ID}"
  log_warn "  Alvo:    ${TARGET_URI}"
  if [[ "${DELETE_BUCKET}" == "true" ]]; then
    log_warn "  Ação:    Remover todos os objetos e EXCLUIR o bucket gs://${BUCKET_NAME}"
  else
    log_warn "  Ação:    Remover objetos correspondentes (incluindo histórico de versões)"
  fi
  echo ""
  read -r -p "Deseja continuar? (digite 'sim' para confirmar): " CONFIRMATION
  if [[ "${CONFIRMATION}" != "sim" && "${CONFIRMATION}" != "SIM" && "${CONFIRMATION}" != "yes" && "${CONFIRMATION}" != "s" ]]; then
    log_info "Operação cancelada pelo usuário."
    exit 0
  fi
fi

# Listagem (Dry-run ou verificação prévia)
log_info "Consultando objetos em ${TARGET_URI}..."
if [[ "${DRY_RUN}" == "true" ]]; then
  RAW_OBJECTS="$(gcloud storage ls --all-versions --recursive "${TARGET_URI}/**" 2>/dev/null || gcloud storage ls --recursive "${TARGET_URI}" 2>/dev/null || true)"
  
  if [[ -z "${RAW_OBJECTS}" ]]; then
    log_info "Nenhum objeto encontrado em ${TARGET_URI}."
  else
    # Identifica os prefixos/diretórios de cada VM
    VM_DIRS="$(echo "${RAW_OBJECTS}" | grep -o 'gs://[^#]*' | sed 's|/[^/]*$||' | sort -u)"

    echo ""
    log_info "=== [DRY-RUN] Instâncias e Recursos Provisionados ==="

    TEMP_STATE="$(mktemp /tmp/tfstate_inspect_XXXXXX.json 2>/dev/null || echo "/tmp/tfstate_inspect_$$.json")"
    trap "rm -f '$TEMP_STATE'" EXIT

    echo "${VM_DIRS}" | while read -r vm_dir; do
      vm_name="$(basename "$vm_dir")"
      if [[ "$vm_name" == "${PREFIX}" || "$vm_name" == "${BUCKET_NAME}" || -z "$vm_name" ]]; then
        continue
      fi

      echo ""
      echo "  📦 Instância: ${vm_name}"
      echo "     Prefixo:   ${vm_dir}"

      # Tenta baixar o tfstate ativo para inspecionar os recursos
      STATE_URI="${vm_dir}/default.tfstate"
      if gcloud storage cp "${STATE_URI}" "${TEMP_STATE}" >/dev/null 2>&1; then
        # Extrai recursos do tfstate usando python3 (disponível na maioria dos runners)
        if command -v python3 >/dev/null 2>&1; then
          RESOURCES="$(python3 -c "
import json, sys
try:
    data = json.load(open('${TEMP_STATE}'))
    resources = data.get('resources', [])
    if not resources:
        print('     (estado vazio — VM já desprovisionada)')
    else:
        print('     Recursos no tfstate:')
        for r in resources:
            rtype = r.get('type', '?')
            rname = r.get('name', '?')
            rmode = r.get('mode', 'managed')
            if rmode == 'data':
                continue
            instances = r.get('instances', [])
            for inst in instances:
                attrs = inst.get('attributes', {})
                ik = inst.get('index_key', '')
                ik_str = f' [\"{ik}\"]' if ik else ''
                detail = ''
                if rtype == 'google_compute_instance':
                    name = attrs.get('name', '')
                    zone = attrs.get('zone', '')
                    mtype = attrs.get('machine_type', '')
                    nifs = attrs.get('network_interface', [])
                    ext_ip = ''
                    if nifs:
                        acs = nifs[0].get('access_config', [])
                        if acs:
                            ext_ip = acs[0].get('nat_ip', '')
                    detail = f'name={name}, zone={zone}, type={mtype}'
                    if ext_ip:
                        detail += f', ip={ext_ip}'
                elif rtype == 'google_compute_firewall':
                    fname = attrs.get('name', '')
                    direction = attrs.get('direction', '')
                    detail = f'name={fname}, direction={direction}'
                elif rtype == 'google_org_policy_policy':
                    pname = attrs.get('name', '')
                    detail = f'policy={pname}'
                else:
                    rid = attrs.get('id', attrs.get('name', ''))
                    if rid:
                        detail = f'id={rid}'
                line = f'       • {rtype}.{rname}{ik_str}'
                if detail:
                    line += f'  ({detail})'
                print(line)
except Exception as e:
    print(f'     ⚠️  Erro ao inspecionar tfstate: {e}')
" 2>/dev/null)" || RESOURCES="     ⚠️  Não foi possível parsear o tfstate."
          echo "${RESOURCES}"
        else
          echo "     ⚠️  python3 não disponível para inspecionar recursos."
        fi
        rm -f "${TEMP_STATE}" 2>/dev/null || true
      else
        echo "     ⚠️  Não foi possível baixar ${STATE_URI} para inspeção."
      fi
    done

    echo ""
    log_info "=== [DRY-RUN] Detalhamento de Arquivos e Versões (Object Versioning) ==="
    echo "  ℹ️  O sufixo '#<geração>' representa uma versão/backup histórico de alterações no mesmo arquivo."
    echo "${RAW_OBJECTS}" | while read -r obj; do
      if [[ -n "$obj" ]]; then
        echo "  • ${obj}"
      fi
    done
  fi

  if [[ "${DELETE_BUCKET}" == "true" ]]; then
    echo ""
    log_info "[DRY-RUN] O bucket gs://${BUCKET_NAME} seria excluído após a limpeza."
  fi
  echo ""
  log_info "[DRY-RUN] Simulação concluída com sucesso. Nenhuma alteração foi realizada."
  exit 0
fi

# Execução da remoção de objetos
log_info "Removendo objetos e versões em ${TARGET_URI}..."
if [[ "${TARGET_URI}" == "gs://${BUCKET_NAME}" ]]; then
  # Remove todos os objetos e versões do bucket inteiro
  gcloud storage rm --recursive --all-versions "gs://${BUCKET_NAME}/**" 2>/dev/null || true
else
  # Remove objetos e versões do prefixo especificado
  gcloud storage rm --recursive --all-versions "${TARGET_URI}/**" 2>/dev/null || \
  gcloud storage rm --recursive "${TARGET_URI}" 2>/dev/null || true
fi

log_info "Limpeza dos objetos concluída."

# Exclusão do bucket se solicitado
if [[ "${DELETE_BUCKET}" == "true" ]]; then
  log_info "Excluindo bucket gs://${BUCKET_NAME} no projeto ${PROJECT_ID}..."
  # Garante remoção de qualquer objeto restante antes de deletar o bucket
  gcloud storage rm --recursive --all-versions "gs://${BUCKET_NAME}/**" 2>/dev/null || true
  gcloud storage buckets delete "gs://${BUCKET_NAME}" --project="${PROJECT_ID}" --quiet
  log_info "Bucket gs://${BUCKET_NAME} excluído com sucesso."
fi

log_info "Operação finalizada com sucesso."
