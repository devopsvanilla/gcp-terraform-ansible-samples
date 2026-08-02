---
applyTo: "**/*.sh"
description: "Padrões de scripts Bash Linux para automações de POCs Terraform"
---

# Bash Linux — Regras do repositório

Estas regras valem para scripts auxiliares de implantação/verificação/descomissionamento.

## Princípios

- Scripts devem ser curtos, legíveis e idempotentes.
- Preferir Bash (Linux), sem dependências obscuras.
- Erros devem falhar cedo, com mensagens claras.

## Padrão mínimo

- Shebang: `#!/usr/bin/env bash`
- Modo estrito: `set -euo pipefail`
- Quoting seguro: `"${var}"`
- Testes com `[[ ... ]]` em vez de `[ ... ]`
- Funções pequenas e `main "$@"` no final para scripts não triviais

## Interface de uso

- Suportar `--help` com exemplos.
- Validar argumentos de entrada.
- Validar dependências externas (`terraform`, `gcloud`, etc.) antes de executar.

## Logs e diagnóstico

- Enviar erros para STDERR.
- Usar prefixos de log (`[INFO]`, `[WARN]`, `[ERROR]`).
- Incluir mensagens de ação/correção em falhas comuns.

## Qualidade

- Scripts novos devem passar em ShellCheck quando possível.
- Evitar `eval` e parsing frágil.

## Referências

- https://google.github.io/styleguide/shellguide.html
- https://www.shellcheck.net/
