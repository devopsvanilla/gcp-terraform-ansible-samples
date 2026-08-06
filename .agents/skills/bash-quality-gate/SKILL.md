---
name: bash-quality-gate
description: Valida scripts Bash Linux quanto a estritismo (set -euo pipefail), segurança, tratamento de erro, --help e ShellCheck.
---

# Skill: Bash Quality Gate

Esta skill garante a segurança e manutenibilidade dos scripts Linux de suporte criados no repositório.

---

## Quando Utilizar esta Skill

- Ao escrever ou modificar scripts `.sh` no repositório (`scripts/`, `PoCs/<nome-da-poc>/scripts/`, etc.).

---

## Checklist de Validação

### 1. Cabeçalho e Modo Estrito
- Shebang padronizado: `#!/usr/bin/env bash`
- Modo de falha rápida ativado logo no início: `set -euo pipefail`

### 2. Sintaxe e Quoting
- Quoting rigoroso de variáveis para prevenir expansão indevida: `"${VAR}"`
- Uso de `[[ ... ]]` para expressões condicionais.
- Funções em `lower_snake_case`. Uso da função `main "$@"` para iniciar o fluxo principal.

### 3. Usabilidade e Erros
- Suporte à flag `--help` ou `-h` exibindo resumo de uso e exemplos.
- Verificação inicial da existência dos binários/dependências requeridos (`command -v terraform >/dev/null 2>&1 || ...`).
- Mensagens de erro direcionadas para STDERR (`echo "..." >&2`).

---

## Comandos de Verificação

```bash
# Executar ShellCheck se disponível
shellcheck script.sh

# Testar chamada de ajuda
bash script.sh --help
```
