#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Uso: create-tfstate-bucket.sh --project-id <project-id> [--location us-central1]

Cria o bucket GCS usado pelo backend remoto do Terraform para armazenar o state.
EOF
}

project_id=""
location="us-central1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-id)
      project_id="${2:-}"
      shift 2
      ;;
    --location)
      location="${2:-}"
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

bucket_name="tfstate-devopsvanilla-samples"

if ! gcloud storage buckets describe "gs://${bucket_name}" --project="${project_id}" >/dev/null 2>&1; then
  echo "Criando bucket gs://${bucket_name} no projeto ${project_id}..."
  gcloud storage buckets create "gs://${bucket_name}" \
    --project="${project_id}" \
    --location="${location}" \
    --uniform-bucket-level-access
else
  echo "Bucket gs://${bucket_name} já existe."
fi

echo "Habilitando versionamento no bucket..."
gcloud storage buckets update "gs://${bucket_name}" \
  --project="${project_id}" \
  --versioning

echo "Pronto. O bucket está disponível para o backend gcs do Terraform."
