#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Setup Script - Ansible Morpheus Core Collection
# ==============================================================================

echo "======================================================================"
echo " [Morpheus Ansible] Instalando dependencias e colecoes..."
echo "======================================================================"

# 1. Verifica se python3 e pip estao instalados
if ! command -v python3 &> /dev/null; then
    echo "[ERRO] Python 3 nao encontrado. Instale com: sudo apt update && sudo apt install -y python3 python3-pip python3-venv"
    exit 1
fi

# 2. Instala dependencias Python necessarias para a colecao morpheus.core
echo "[1/4] Instalando dependencias Python (requests, packaging)..."
python3 -m pip install --upgrade requests packaging ansible-core || {
    echo "[AVISO] Tentando instalar com --break-system-packages (ambiente Ubuntu moderno)..."
    python3 -m pip install --upgrade requests packaging --break-system-packages 2>/dev/null || true
}

# 3. Instala a colecao morpheus.core via requirements.yml
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

echo "[2/4] Instalando colecao morpheus.core via ansible-galaxy..."
ansible-galaxy collection install -r "${BASE_DIR}/requirements.yml" --upgrade

# 4. Validacao da instalacao
echo "[3/4] Validando colecoes instaladas..."
ansible-galaxy collection list | grep -i morpheus || echo "[ALERTA] Colecao morpheus nao encontrada na listagem padrao"

echo "[4/4] Validando plugin de inventario..."
if ansible-doc -t inventory -l 2>/dev/null | grep -i morpheus; then
    echo "[OK] Plugin morpheus_inventory disponivel!"
else
    echo "[AVISO] Plugin morpheus_inventory pode requerer Ansible >= 2.10 ou configuracao no ansible.cfg"
fi

echo "======================================================================"
echo " [Morpheus Ansible] Setup concluido com sucesso!"
echo "======================================================================"
