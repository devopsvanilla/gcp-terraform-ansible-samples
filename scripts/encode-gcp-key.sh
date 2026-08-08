#!/usr/bin/env bash
# Utilitário para gerar a credencial GCP codificada em Base64 para armazenar no Morpheus Cypher.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_FILE="${1:-$SCRIPT_DIR/gcp-key.json}"

if [[ ! -f "$KEY_FILE" ]]; then
  echo "[ERRO] Arquivo de chave não encontrado em: $KEY_FILE" >&2
  echo "Uso: $0 [caminho/para/gcp-key.json]" >&2
  exit 1
fi

echo "========================================================================="
echo "   CHAVE GCP EM BASE64 PARA ARMAZENAR NO MORPHEUS CYPHER"
echo "========================================================================="
echo "Copie TODO o texto abaixo e cole no campo 'Value' do segredo no Cypher:"
echo "Key: secret/gcp-terraform-ansible-samples"
echo "Type: Secret"
echo "-------------------------------------------------------------------------"
python3 -c "import base64; print(base64.b64encode(open('$KEY_FILE', 'rb').read()).decode('utf-8'))"
echo "-------------------------------------------------------------------------"
