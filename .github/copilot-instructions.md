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

- **Ansible (Automação Geral & HPE Morpheus Core)**:
  - Organizado em `PoCs/<nome-da-poc>/ansible/` com `requirements.yml`.
  - Para construção, diagnóstico, documentação e automações Morpheus Data, basear-se na coleção oficial [`morpheus.core`](https://github.com/HewlettPackard/ansible-collection-morpheus-core) da HPE.
  - Tasks com `name` descritivo e módulos nativos idempotentes (Ansible Core e `morpheus.core`).
  - Autenticação e tokens (`MORPHEUS_API_URL`, `MORPHEUS_API_TOKEN` / `MORPHEUS_ACCESS_TOKEN`) via variáveis de ambiente ou Ansible Vault, nunca expostos em texto plano.

- **Bash Linux**:
  - `#!/usr/bin/env bash` e `set -euo pipefail`.
  - Suporte a `--help`, quoting seguro (`"${var}"`) e tratamento de erros direcionado a STDERR.

---

## 4. Fluxo de Trabalho em 3 Fases

- **Fase 1: Diagnóstico** — Avaliar estrutura e propor plano incremental.
- **Fase 2: Implementação** — Escrever código e documentação em pt-BR.
- **Fase 3: Validação** — Executar quality gates (`terraform fmt`, `shellcheck`, `ansible-lint`, `markdownlint`).

---

## 5. Referências Oficiais HPE Morpheus Data

- Provedor Terraform HPE: <https://registry.terraform.io/providers/HPE/hpe/latest>
- Coleção Ansible Morpheus Core (HPE): <https://github.com/HewlettPackard/ansible-collection-morpheus-core>
- Documentação e API Morpheus Data: <https://support.hpe.com/hpesc/public/docDisplay?docId=sd00008014en_us&page=GUID-709AAADB-A9C1-40B6-AD22-958EE7E6F312.html>

<!-- mermaid-ai-skills:start -->
## Mermaid Diagrams

When the user asks to create, edit, or visualize a diagram, follow the
instructions in `.github/instructions/mermaid.instructions.md`.
<!-- mermaid-ai-skills:end -->
