#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Uso: setup-gcp-project.sh [--project-id <project-id>] [--instance <instance-name>] [--zone <zone>] [--skip-external-ip]

Configura o projeto GCP para que a automação Terraform desta PoC funcione, incluindo:
- habilitar APIs necessárias (Compute Engine, Org Policy, Service Usage, IAM, Cloud Resource Manager)
- definir o quota project para a conta ADC atual
- permitir o uso de IP externo para o projeto, com a instância alvo como referência apenas quando ela for fornecida, quando aplicável

Se --project-id não for informado, o script solicitará o valor em um prompt.
EOF
}

project_id=""
instance_name=""
zone=""
allow_external_ip=true

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-id)
      project_id="${2:-}"
      shift 2
      ;;
    --instance)
      instance_name="${2:-}"
      shift 2
      ;;
    --zone)
      zone="${2:-}"
      shift 2
      ;;
    --skip-external-ip)
      allow_external_ip=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Argumento inválido: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "${project_id}" ]]; then
  read -r -p "Informe o ID do projeto GCP: " project_id
fi

if [[ -z "${project_id}" ]]; then
  echo "Erro: o ID do projeto é obrigatório." >&2
  exit 1
fi

if ! command -v gcloud >/dev/null 2>&1; then
  echo "Erro: gcloud não encontrado no PATH." >&2
  exit 1
fi

if ! gcloud auth list --filter=status:ACTIVE --format='value(account)' | grep -q .; then
  echo "Erro: nenhuma conta ativa do gcloud foi encontrada. Execute 'gcloud auth login' ou 'gcloud auth application-default login'." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
po_c_dir="$(cd "${script_dir}/.." && pwd)"
tfvars_path="${po_c_dir}/terraform.tfvars"

if [[ -z "${instance_name}" ]]; then
  instance_name="$(awk -F'"' '/^[[:space:]]*vm_name[[:space:]]*=/{print $2; exit}' "${tfvars_path}" 2>/dev/null || true)"
fi

if [[ -z "${zone}" ]]; then
  zone="$(awk -F'"' '/^[[:space:]]*zone[[:space:]]*=/{print $2; exit}' "${tfvars_path}" 2>/dev/null || true)"
fi

if [[ -z "${instance_name}" ]]; then
  instance_name="vm-nginx-poc"
fi

if [[ -z "${zone}" ]]; then
  zone="us-central1-a"
fi

active_account="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' | head -n 1)"

cat <<EOF
Pré-flight do projeto GCP
=========================
Projeto: ${project_id}
Conta ativa: ${active_account}
Instância alvo para IP externo: ${instance_name}
Zona: ${zone}

As seguintes configurações serão aplicadas:
- habilitar APIs: compute.googleapis.com, orgpolicy.googleapis.com, serviceusage.googleapis.com, iam.googleapis.com, cloudresourcemanager.googleapis.com
- definir o quota project para a conta ADC atual
- configurar o projeto ativo no gcloud
- permitir o uso de IP externo para o projeto, usando a instância ${instance_name} como referência quando ela for informada, se --skip-external-ip não for informado
EOF

echo
read -r -p "Prosseguir com as alterações? [s/N] " confirm
case "$confirm" in
  s|S|y|Y|yes|YES)
    ;;
  *)
    echo "Operação cancelada pelo usuário."
    exit 0
    ;;
esac

echo "Configurando projeto ${project_id}..."
gcloud config set project "${project_id}" >/dev/null

for service in serviceusage.googleapis.com compute.googleapis.com orgpolicy.googleapis.com iam.googleapis.com cloudresourcemanager.googleapis.com; do
  echo "Habilitando ${service}..."
  gcloud services enable "${service}" --project="${project_id}" >/dev/null
  echo "OK"
done

echo "Definindo quota project para a conta ADC atual..."
gcloud auth application-default set-quota-project "${project_id}" >/dev/null

echo "Quota project configurado."

if [[ "${allow_external_ip}" == true ]]; then
  policy_name="projects/${project_id}/policies/compute.vmExternalIpAccess"
  echo "Configurando política de IP externo (compute.vmExternalIpAccess) para o projeto ${project_id}..."

  tmp_policy="$(mktemp)"
  if [[ -n "${instance_name}" && -n "${zone}" && "${instance_name}" != "vm-nginx-poc" ]]; then
    echo "Aplicando allowlist para a instância ${instance_name} (${zone})..."
    allowed_value="projects/${project_id}/zones/${zone}/instances/${instance_name}"
    cat > "${tmp_policy}" <<EOF_JSON
{
  "name": "${policy_name}",
  "spec": {
    "rules": [
      {
        "values": {
          "allowedValues": [
            "${allowed_value}"
          ]
        }
      }
    ]
  }
}
EOF_JSON
  else
    echo "Liberando uso de IP externo para todas as VMs do projeto (allowAll: true)..."
    cat > "${tmp_policy}" <<EOF_JSON
{
  "name": "${policy_name}",
  "spec": {
    "rules": [
      {
        "allowAll": true
      }
    ]
  }
}
EOF_JSON
  fi

  gcloud org-policies set-policy "${tmp_policy}" --project="${project_id}" >/dev/null
  rm -f "${tmp_policy}"
  echo "Política de IP externo aplicada com sucesso."
fi

echo "Setup concluído."
