#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
AUTO_CONFIRM="false"
MISSING_COMMANDS=()

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

Verifica e instala as dependências necessárias para executar os scripts desta PoC no Ubuntu local.
Se já estiverem instaladas, mantém as ferramentas e só instala o que estiver faltando.
Use este script como a forma padrão de preparar a estação de trabalho antes de usar os scripts da PoC.

Opções:
  --yes, -y   Executa sem confirmação interativa.
  --help, -h  Exibe esta ajuda.

Exemplos:
  ./${SCRIPT_NAME}
  ./${SCRIPT_NAME} --yes
EOF
}

require_command() {
  local command_name="$1"
  command -v "$command_name" >/dev/null 2>&1
}

append_missing_command() {
  local command_name="$1"
  MISSING_COMMANDS+=("${command_name}")
}

package_manager_install() {
  local -a packages_to_install=("$@")
  if [[ ${#packages_to_install[@]} -eq 0 ]]; then
    return 0
  fi

  log_info "Instalando pacotes ausentes: ${packages_to_install[*]}"
  sudo apt-get install -y "${packages_to_install[@]}"
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
  2) Instalação de dependências base do sistema:
     - ca-certificates
     - curl
     - gpg
     - lsb-release
     - software-properties-common
     - apt-transport-https
     - python3
     - python3-pip
     - python3-venv
     - pipx
  3) Configuração do repositório oficial da HashiCorp (Terraform), se terraform estiver ausente
  4) Configuração do PPA oficial do Ansible, se ansible/ansible-lint estiverem ausentes
  5) Configuração do repositório oficial do Google Cloud CLI, se gcloud estiver ausente
  6) Instalação das ferramentas ausentes nesta estação:
     - terraform
     - ansible
     - ansible-dev-tools (via pipx, para fornecer ansible-lint)
     - google-cloud-cli
  7) Testes finais de validação

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
  sudo apt-get install -y ca-certificates curl gpg lsb-release software-properties-common apt-transport-https python3 python3-pip python3-venv pipx
}

configure_hashicorp_repo() {
  if require_command terraform; then
    log_info "Terraform já está presente; repositório HashiCorp não será alterado."
    return 0
  fi

  log_info "Configurando repositório oficial da HashiCorp para Terraform..."

  if [[ ! -f /usr/share/keyrings/hashicorp-archive-keyring.gpg ]]; then
    curl -fsSL "https://apt.releases.hashicorp.com/gpg" \
      | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  fi

  if [[ ! -f /etc/apt/sources.list.d/hashicorp.list ]]; then
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${VERSION_CODENAME} main" \
      | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
  fi
}

configure_ansible_repo() {
  if require_command ansible && require_command ansible-lint; then
    log_info "Ansible e ansible-lint já estão presentes; repositório do Ansible não será alterado."
    return 0
  fi

  log_info "Configurando PPA oficial do Ansible..."
  sudo add-apt-repository -y ppa:ansible/ansible
}

configure_google_cloud_repo() {
  if require_command gcloud; then
    log_info "Google Cloud CLI já está presente; repositório do Google Cloud não será alterado."
    return 0
  fi

  log_info "Configurando repositório oficial do Google Cloud CLI..."

  if [[ ! -f /usr/share/keyrings/cloud.google.gpg ]]; then
    curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" \
      | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
  fi

  if [[ ! -f /etc/apt/sources.list.d/google-cloud-cli.list ]]; then
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      | sudo tee /etc/apt/sources.list.d/google-cloud-cli.list >/dev/null
  fi
}

check_requirements() {
  log_info "Verificando dependências necessárias para os scripts da PoC..."

  if require_command python3; then
    log_info "python3 já está instalado."
  else
    append_missing_command "python3"
  fi

  if require_command terraform; then
    log_info "terraform já está instalado."
  else
    append_missing_command "terraform"
  fi

  if require_command ansible; then
    log_info "ansible já está instalado."
  else
    append_missing_command "ansible"
  fi

  if require_command ansible-lint; then
    log_info "ansible-lint já está instalado."
  else
    append_missing_command "ansible-dev-tools"
  fi

  if require_command gcloud; then
    log_info "gcloud já está instalado."
  else
    append_missing_command "google-cloud-cli"
  fi
}

install_missing_tools() {
  local -a packages_to_install=()
  local need_ansible_dev_tools="false"

  for command_name in "${MISSING_COMMANDS[@]}"; do
    case "${command_name}" in
      python3)
        packages_to_install+=("python3" "python3-pip" "python3-venv")
        ;;
      terraform)
        packages_to_install+=("terraform")
        ;;
      ansible)
        packages_to_install+=("ansible")
        ;;
      ansible-dev-tools)
        need_ansible_dev_tools="true"
        ;;
      google-cloud-cli)
        packages_to_install+=("google-cloud-cli")
        ;;
      *)
        log_warn "Ignorando mapeamento desconhecido para ${command_name}."
        ;;
    esac
  done

  if [[ ${#packages_to_install[@]} -eq 0 ]]; then
    log_info "Nenhuma dependência faltando foi encontrada."
  else
    log_info "Atualizando índice do APT antes da instalação..."
    sudo apt-get update -y

    package_manager_install "${packages_to_install[@]}"
  fi

  if [[ "${need_ansible_dev_tools}" == "true" ]]; then
    if ! require_command pipx; then
      die "pipx não foi instalado corretamente; ele é necessário para instalar ansible-dev-tools."
    fi

    log_info "Instalando ansible-dev-tools via pipx para fornecer ansible-lint..."
    pipx ensurepath >/dev/null 2>&1 || true
    pipx install --include-deps --force ansible-dev-tools
  fi
}

run_final_tests() {
  log_info "Executando testes finais..."

  if ! command -v python3 >/dev/null 2>&1; then
    log_error "python3 não encontrado no PATH após instalação/atualização."
    exit 1
  fi

  if ! command -v terraform >/dev/null 2>&1; then
    log_error "Terraform não encontrado no PATH após instalação/atualização."
    exit 1
  fi

  if ! command -v ansible >/dev/null 2>&1; then
    log_error "Ansible não encontrado no PATH após instalação/atualização."
    exit 1
  fi

  if ! command -v ansible-lint >/dev/null 2>&1; then
    log_error "ansible-lint não encontrado no PATH após instalação/atualização."
    exit 1
  fi

  if ! command -v gcloud >/dev/null 2>&1; then
    log_error "gcloud não encontrado no PATH após instalação/atualização."
    exit 1
  fi

  log_info "Versão do Python: $(python3 --version)"
  log_info "Versão do Terraform: $(terraform -version | head -n 1)"
  log_info "Versão do Ansible: $(ansible --version | head -n 1)"
  log_info "Versão do ansible-lint: $(ansible-lint --version | head -n 1)"
  log_info "Versão do gcloud: $(gcloud --version | head -n 1)"

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
  check_requirements
  configure_hashicorp_repo
  configure_ansible_repo
  configure_google_cloud_repo
  install_missing_tools
  run_final_tests
}

main "$@"