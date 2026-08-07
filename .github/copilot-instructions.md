# GitHub Copilot Instructions — Diretrizes do Repositório

Este arquivo estabelece os padrões e regras obrigatórias que o GitHub Copilot deve seguir ao gerar, alterar ou sugerir trechos de código e documentação neste repositório.

---

## 1. Idioma e Qualidade de Documentação

1. **Português do Brasil (pt-BR)**
   - Toda e qualquer documentação (READMEs, guias HOWTO, explicações, comentários de código e especificações de prompts) deve ser redigida obrigatoriamente em **Português do Brasil (pt-BR)**.

2. **Validação via Markdown Lint**
   - Todos os arquivos Markdown (`.md`) criados ou alterados devem seguir rigorosamente os padrões do **markdown lint** (`markdownlint` ou `pymarkdown scan`), incluindo formatação correta de títulos, parágrafos, blocos de código e listas.

---

## 2. Padrões de Estrutura do Repositório

1. **Caminho Obrigatório de POCs**
   - Toda Prova de Conceito deve ser criada exclusivamente sob a estrutura `PoCs/<nome-da-poc>/` (prefixo `PoCs/` com maiúsculas).

2. **Estrutura de README da POC (6 Seções Estritas)**
   - Cada `PoCs/<nome-da-poc>/README.md` deve conter exatamente estas 6 seções na ordem correta:
     1. `O que será implantado`
     2. `Pré-requisitos`
     3. `Como implantar`
     4. `Como conferir a implantação`
     5. `Como descomissionar`
     6. `Guia de erros comuns`

3. **README da Raiz (`/README.md`)**
   - Manter atualizado com o índice de POCs existentes e visões gerais do projeto.

---

## 3. Padrões por Tecnologia

- **Terraform (GCP & HPE Morpheus Data)**:
  - Separação por intenção (`versions.tf`, `providers.tf`, `main.tf`, `variables.tf`, `outputs.tf`).
  - Provedor oficial Morpheus Data: `HPE/hpe` (`https://registry.terraform.io/providers/HPE/hpe/latest`).
  - Variáveis e outputs sempre com `description`. Segredos com `sensitive = true`.
  - Nomenclatura em `snake_case`. Sem credenciais hardcoded.

- **Ansible**:
  - Organizado em `PoCs/<nome-da-poc>/ansible/`.
  - Tasks com `name` descritivo e módulos nativos idempotentes.

- **Bash Linux**:
  - `#!/usr/bin/env bash` e `set -euo pipefail`.
  - Suporte a `--help`, quoting seguro (`"${var}"`) e tratamento de erros direcionado a STDERR.

---

## 4. Fluxo de Trabalho em 3 Fases

- **Fase 1: Diagnóstico** — Avaliar estrutura e propor plano incremental.
- **Fase 2: Implementação** — Escrever código e documentação em pt-BR.
- **Fase 3: Validação** — Executar quality gates (`terraform fmt`, `shellcheck`, `ansible-lint`, `markdownlint`).
