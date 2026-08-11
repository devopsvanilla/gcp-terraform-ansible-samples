#!/usr/bin/env bash
set -euo pipefail

# Script para extrair e formatar credenciais de Service Account GCP
# para copiar e colar na interface do Morpheus Data (Cloud Integration ou Cypher).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

KEY_FILE=""

# Procura o arquivo gcp-key.json nos locais padrão se não for fornecido via argumento
if [[ $# -gt 0 ]]; then
  KEY_FILE="$1"
elif [[ -f "${SCRIPT_DIR}/gcp-key.json" ]]; then
  KEY_FILE="${SCRIPT_DIR}/gcp-key.json"
elif [[ -f "${REPO_ROOT}/gcp-key.json" ]]; then
  KEY_FILE="${REPO_ROOT}/gcp-key.json"
elif [[ -f "./gcp-key.json" ]]; then
  KEY_FILE="./gcp-key.json"
else
  echo "Erro: Arquivo gcp-key.json não encontrado." >&2
  echo "Uso: $0 [caminho/para/gcp-key.json]" >&2
  echo "Ou execute o comando de geração do gcloud dentro do diretório ./scripts:" >&2
  echo "  cd scripts && gcloud iam service-accounts keys create gcp-key.json --iam-account=..." >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "Erro: python3 é necessário para formatar a chave." >&2
  exit 1
fi

echo "================================================================================"
echo " CREDENCIAIS EXTRAÍDAS DE: ${KEY_FILE}"
echo "================================================================================"
echo

python3 - "$KEY_FILE" <<'EOF'
import json
import sys

key_path = sys.argv[1]
try:
    with open(key_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception as e:
    print(f"Erro ao ler o arquivo JSON ({key_path}): {e}", file=sys.stderr)
    sys.exit(1)

client_email = data.get("client_email", "")
project_id = data.get("project_id", "")
private_key = data.get("private_key", "")

print("1. EMAIL DO CLIENTE (Copiar e colar no campo 'EMAIL DO CLIENTE' do Morpheus):")
print("-" * 80)
print(client_email)
print("-" * 80)
print()

print("2. ID DO PROJETO (Para verificação):")
print("-" * 80)
print(project_id)
print("-" * 80)
print()

print("3. CHAVE PRIVADA (Copiar todo o bloco abaixo e colar no campo 'CHAVE PRIVADA' do Morpheus):")
print("-" * 80)
print(private_key.strip())
print("-" * 80)
print()

EOF
