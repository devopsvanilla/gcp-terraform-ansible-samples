#!/usr/bin/env bash
set -euo pipefail

payload="$(cat)"

# Bloqueia uso do caminho legado `pocs/` para forçar padrão `PoCs/`.
if printf '%s' "${payload}" | grep -Eiq '(^|["`/\\])pocs/'; then
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Diretório inválido detectado: use `PoCs/` em vez de `pocs/`."
  },
  "systemMessage": "Padrão de diretório obrigatório: use `PoCs/<nome-da-poc>/` em todos os caminhos de arquivos."
}
JSON
  exit 0
fi

cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow",
    "permissionDecisionReason": "Sem violação de caminho `pocs/`."
  }
}
JSON
