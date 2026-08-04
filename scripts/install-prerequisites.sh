#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
AUTO_CONFIRM="false"

log_info() {
  echo "[INFO] $*"
}

log_warn() {
  echo "[WARN] $*"
}

log_error() {
  echo "[ERROR] $*" >&2
}

usage() {
  cat <<EOF
Uso: ${SCRIPT_NAME} [--yes] [--help]

Instala e configura Terraform + Ansible no Ubuntu local.
Se já estiverem instalados, atualiza para a versão mais recente disponível.

Opções:
  --yes, -y   Executa sem confirmação interativa.
  --help, -h  Exibe esta ajuda.

Exemplos:
  ./${SCRIPT_NAME}
  ./${SCRIPT_NAME} --yes
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --yes|-y)
        AUTO_CONFIRM="true"
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        log_error "Argumento inválido: $1"
        usage
        exit 1
        ;;
    esac
  done
}

require_ubuntu() {
  if [[ ! -f /etc/os-release ]]; then
    log_error "Não foi possível identificar o sistema operacional (/etc/os-release ausente)."
    exit 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release

  if [[ "${ID:-}" != "ubuntu" ]]; then
    log_error "Este script suporta apenas Ubuntu. Sistema detectado: ${PRETTY_NAME:-desconhecido}."
    exit 1
  fi

  log_info "Sistema detectado: ${PRETTY_NAME}."
}

confirm_execution() {
  if [[ "${AUTO_CONFIRM}" == "true" ]]; then
    log_warn "Confirmação interativa ignorada por --yes."
    return 0
  fi

  cat <<'EOF'
Este script vai executar:
  1) Atualização de índices do APT
  2) Configuração do repositório oficial da HashiCorp (Terraform)
  3) Configuração do PPA oficial do Ansible
  4) Instalação/atualização de terraform e ansible
  5) Testes finais de validação

É necessário acesso sudo.
EOF

  read -r -p "Deseja continuar? (s/N): " answer
  case "${answer}" in
    s|S|sim|SIM|y|Y|yes|YES)
      log_info "Execução confirmada pelo usuário."
      ;;
    *)
      log_warn "Execução cancelada pelo usuário."
      exit 0
      ;;
  esac
}

require_sudo() {
  if [[ "${EUID}" -eq 0 ]]; then
    log_warn "Executando como root."
    return 0
  fi

  log_info "Validando permissão sudo..."
  sudo -v
}

install_base_dependencies() {
  log_info "Instalando dependências base para configuração de repositórios..."
  sudo apt-get update -y
  sudo apt-get install -y ca-certificates curl gpg lsb-release software-properties-common
}

configure_hashicorp_repo() {
  log_info "Configurando repositório oficial da HashiCorp para Terraform..."

  curl -fsSL "https://apt.releases.hashicorp.com/gpg" \
    | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${VERSION_CODENAME} main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
}

configure_ansible_repo() {
  log_info "Configurando PPA oficial do Ansible..."
  sudo add-apt-repository -y ppa:ansible/ansible
}

install_or_upgrade_terraform_ansible() {
  log_info "Instalando/atualizando Terraform e Ansible..."
  sudo apt-get update -y
  sudo apt-get install -y terraform ansible
}

run_final_tests() {
  log_info "Executando testes finais..."

  if ! command -v terraform >/dev/null 2>&1; then
    log_error "Terraform não encontrado no PATH após instalação/atualização."
    exit 1
  fi

  if ! command -v ansible >/dev/null 2>&1; then
    log_error "Ansible não encontrado no PATH após instalação/atualização."
    exit 1
  fi

  log_info "Versão do Terraform: $(terraform -version | head -n 1)"
  log_info "Versão do Ansible: $(ansible --version | head -n 1)"

  log_info "Testando Ansible localmente (localhost ping)..."
  ansible localhost -i "localhost," -c local -m ping >/dev/null

  log_info "Validação concluída com sucesso: Terraform e Ansible estão prontos para uso."
}

main() {
  parse_args "$@"
  require_ubuntu
  confirm_execution
  require_sudo
  install_base_dependencies
  configure_hashicorp_repo
  configure_ansible_repo
  install_or_upgrade_terraform_ansible
  run_final_tests
}

main "$@"