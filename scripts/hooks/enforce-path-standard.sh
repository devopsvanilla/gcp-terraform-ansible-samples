#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"
legacy_dir="$(printf '\160\157\143\163/')"

# Bloqueia uso do caminho legado em minúsculas e mantém padrão oficial do repositório.
if printf '%s' "${payload}" | grep -Eq "(^|[\"\`/\\])${legacy_dir}"; then
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Diretório inválido detectado: use o padrão oficial do repositório para PoCs."
  },
  "systemMessage": "Padrão de diretório obrigatório: use a convenção oficial deste repositório para as PoCs."
}
JSON
  exit 0
fi

cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Sem violação de padrão de caminho legado."
  }
}
JSON
