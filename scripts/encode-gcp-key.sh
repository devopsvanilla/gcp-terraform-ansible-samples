#!/usr/bin/env bash
# Utilitário para formatar a credencial GCP para armazenamento no Morpheus Cypher ou terraform.tfvars.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_FILE="${1:-$SCRIPT_DIR/gcp-key.json}"

if [[ ! -f "$KEY_FILE" ]]; then
  echo "[ERRO] Arquivo de chave não encontrado em: $KEY_FILE" >&2
  echo "Uso: $0 [caminho/para/gcp-key.json]" >&2
  exit 1
fi

echo "========================================================================="
echo "   1. FORMATO JSON EM LINHA ÚNICA (RECOMENDADO PARA PROVIDER GOOGLE)"
echo "========================================================================="
echo "Copie o texto JSON abaixo e cole em gcp_credentials no terraform.tfvars:"
echo "-------------------------------------------------------------------------"
jq -c . "$KEY_FILE"
echo "-------------------------------------------------------------------------"
echo ""
echo "========================================================================="
echo "   2. FORMATO BASE64 (PARA SEGREDO CENTRAL secret/gcp-terraform-ansible-samples)"
echo "========================================================================="
python3 -c "import base64; print(base64.b64encode(open('$KEY_FILE', 'rb').read()).decode('utf-8'))"
echo "-------------------------------------------------------------------------"
