#!/usr/bin/env bash
# Utilitário para formatar a credencial GCP para armazenamento no Morpheus Cypher ou terraform.tfvars.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

KEY_FILE=""

# Procura o arquivo gcp-key.json nos locais padrao se nao for fornecido via argumento
if [[ $# -gt 0 ]]; then
  KEY_FILE="$1"
elif [[ -f "${SCRIPT_DIR}/gcp-key.json" ]]; then
  KEY_FILE="${SCRIPT_DIR}/gcp-key.json"
elif [[ -f "${REPO_ROOT}/gcp-key.json" ]]; then
  KEY_FILE="${REPO_ROOT}/gcp-key.json"
elif [[ -f "./gcp-key.json" ]]; then
  KEY_FILE="./gcp-key.json"
else
  echo "[ERRO] Arquivo de chave nao encontrado em: ${SCRIPT_DIR}/gcp-key.json" >&2
  echo "Uso: $0 [caminho/para/gcp-key.json]" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "[ERRO] python3 e necessario para formatar a chave." >&2
  exit 1
fi

echo "========================================================================="
echo "   1. FORMATO JSON COM ESCAPE (PARA gcp_credentials NO terraform.tfvars)"
echo "========================================================================="
echo "Copie o texto abaixo e cole dentro das aspas em gcp_credentials no terraform.tfvars:"
echo 'Exemplo: gcp_credentials = "<COLE_AQUI>"'
echo "-------------------------------------------------------------------------"
python3 - "$KEY_FILE" <<'EOF'
import json
import sys

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)

print(json.dumps(json.dumps(data))[1:-1])
EOF
echo "-------------------------------------------------------------------------"
echo ""
echo "========================================================================="
echo "   2. FORMATO BASE64 (PARA SEGREDO CENTRAL secret/gcp-terraform-ansible-samples)"
echo "========================================================================="
python3 - "$KEY_FILE" <<'EOF'
import base64
import sys

with open(sys.argv[1], 'rb') as f:
    print(base64.b64encode(f.read()).decode('utf-8'))
EOF
echo "-------------------------------------------------------------------------"
