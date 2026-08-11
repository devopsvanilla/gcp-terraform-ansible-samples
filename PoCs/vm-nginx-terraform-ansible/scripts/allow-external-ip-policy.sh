#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Uso: allow-external-ip-policy.sh --project-id <project-id> [--instance <instance-name>] [--zone <zone>]

Habilita temporariamente o uso de IP externo para o projeto,
ajustando a Org Policy constraints/compute.vmExternalIpAccess para permitir o uso de IP externo em VMs criadas nesse projeto.
Os parâmetros --instance e --zone são opcionais e servem apenas como referência para uma instância específica, quando desejado.
EOF
}

project_id=""
instance_name=""
zone=""

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
  echo "Erro: --project-id é obrigatório." >&2
  usage >&2
  exit 1
fi

if ! command -v gcloud >/dev/null 2>&1; then
  echo "Erro: gcloud não encontrado no PATH." >&2
  exit 1
fi

policy_name="projects/${project_id}/policies/compute.vmExternalIpAccess"
if [[ -n "${instance_name}" && -n "${zone}" ]]; then
  allowed_value="projects/${project_id}/zones/${zone}/instances/${instance_name}"
else
  allowed_value="projects/${project_id}/zones/us-central1-a/instances/vm-nginx-poc"
fi

if ! gcloud services list --enabled --project="${project_id}" --format='value(config.name)' | grep -qx 'orgpolicy.googleapis.com'; then
  echo "Habilitando orgpolicy.googleapis.com no projeto ${project_id}..."
  gcloud services enable orgpolicy.googleapis.com --project="${project_id}"
fi

if [[ -n "${instance_name}" && -n "${zone}" ]]; then
  echo "Aplicando allowlist para a instância ${instance_name} no projeto ${project_id}..."
else
  echo "Aplicando policy de IP externo para o projeto ${project_id}..."
fi

cat > /tmp/vm-external-ip-policy.json <<EOF
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
EOF

gcloud org-policies set-policy /tmp/vm-external-ip-policy.json \
  --project="${project_id}"

rm -f /tmp/vm-external-ip-policy.json

if [[ -n "${instance_name}" && -n "${zone}" ]]; then
  echo "Pronto. A VM ${instance_name} foi adicionada à allowlist de IP externo para o projeto ${project_id}."
else
  echo "Pronto. A política de IP externo foi aplicada ao projeto ${project_id}."
fi
