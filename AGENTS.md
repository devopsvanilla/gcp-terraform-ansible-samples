# AGENTS.md

## Objetivo deste repositório

Este repositório é dedicado a **provas de conceito (POCs) em Terraform para GCP e Morpheus Data (via provedor oficial `HPE/hpe`)**, com suporte opcional a **Ansible** para provisionamento e configuração de serviços, e scripts auxiliares em **Bash Linux**.

As POCs devem implantar **unidades mínimas de software ou configuração** que comprovem funcionamento com baixo custo, simplicidade e facilidade de limpeza (`terraform destroy`).

---

## Escopo para Agentes de IA e GitHub Copilot

Ao criar ou alterar conteúdo neste repositório, siga estritamente estas regras:

1. **Documentação em Português do Brasil (pt-BR)**:
   - Toda e qualquer documentação (READMEs, HOWTOs, skills, prompts, instruções e comentários) deve ser redigida em **Português do Brasil (pt-BR)**.

2. **Validação via Markdown Lint**:
   - Todo documento Markdown (`.md`) criado ou alterado deve passar por validação com **markdown lint** (`markdownlint` ou `pymarkdown scan`), respeitando boas práticas de formatação.

3. **Foque em POCs mínimas e verificáveis**:
   - Cada POC deve ser pequena, objetiva e com validação clara.

4. **Uma POC por diretório próprio**:
   - Use obrigatoriamente o padrão: `PoCs/<nome-da-poc>/` (prefixo `PoCs/` com maiúsculas).

5. **README obrigatório por POC (6 seções estritas)**:
   - Cada `PoCs/<nome-da-poc>/README.md` deve conter exatamente as seguintes seções na ordem exata:
     1. `O que será implantado`
     2. `Pré-requisitos`
     3. `Como implantar`
     4. `Como conferir a implantação`
     5. `Como descomissionar`
     6. `Guia de erros comuns`

6. **README raiz obrigatório (`/README.md`)**:
   - O `README.md` da raiz deve descrever o propósito do projeto, pré-requisitos gerais e servir de índice atualizado das POCs.

7. **Terraform com boas práticas (GCP e HPE Morpheus Data)**:
   - Divida em arquivos por intenção (`versions.tf`, `providers.tf`, `main.tf`, `variables.tf`, `outputs.tf`).
   - Para Morpheus Data, declare o provedor oficial `HPE/hpe` (`https://registry.terraform.io/providers/HPE/hpe/latest`).
   - Variáveis e outputs sempre documentados com `description`. Marcação `sensitive = true` para tokens de acesso e URLs sensíveis.
   - Nomes em `snake_case` sem redundância de tipo.
   - Versionamento explícito de provider/terraform.
   - Sem segredos ou credenciais hardcoded.

8. **Ansible com boas práticas**:
   - Playbooks em `PoCs/<nome-da-poc>/ansible/`.
   - Tasks idempotentes com nomes descritivos.
   - Priorizar módulos nativos Ansible; usar `handlers` para reinícios de serviço.

9. **Scripts preferencialmente em Bash Linux**:
   - Iniciar com `#!/usr/bin/env bash` e `set -euo pipefail`.
   - Quoting seguro (`"${var}"`), suporte a `--help` e tratamento de erros direcionado a STDERR.

10. **Fluxo em 3 Fases**:
    - Execute modificações utilizando o fluxo em 3 fases (Fase 1: Diagnóstico → Fase 2: Implementação → Fase 3: Validação).

11. **Use as Skills do repositório (`.agents/skills/`)**:
    - `poc-scaffold`: Automação de scaffolding de POCs.
    - `poc-readme-validator`: Validação das 6 seções do README.
    - `terraform-quality-gate`: Quality Gate de Terraform GCP e HPE Morpheus.
    - `ansible-quality-gate`: Quality Gate de Ansible.
    - `bash-quality-gate`: Quality Gate de Bash Linux.

---

## Estrutura recomendada de uma POC

```text
PoCs/<nome-da-poc>/
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── providers.tf
├── terraform.tfvars.example
├── README.md
├── ansible/            (opcional: playbooks, roles e inventários)
│   ├── site.yml
│   ├── inventories/
│   ├── group_vars/
│   └── roles/
└── scripts/            (opcional: scripts bash de apoio)
```

---

## Convenções de qualidade

- **Markdown**: `pymarkdown scan` ou `markdownlint` (todos os documentos `.md` obrigatoriamente em Português do Brasil).
- **Terraform**: `terraform fmt`, `terraform validate`, `terraform plan`.
- **Bash**: `shellcheck`, `set -euo pipefail`, `--help`.
- **Ansible**: `ansible-lint`, `ansible-playbook --syntax-check`, `ansible-playbook --check --diff`.

---

## Referências oficiais

### Terraform & GCP

- Terraform Style Guide: <https://developer.hashicorp.com/terraform/language/style>
- Terraform no Google Cloud: <https://docs.cloud.google.com/docs/terraform>
- GCP Terraform Best Practices: <https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure>

### HPE Morpheus Data

- Provedor Terraform HPE: <https://registry.terraform.io/providers/HPE/hpe/latest>
- Configurações da solução e uso da console web: <https://support.hpe.com/hpesc/public/docDisplay?docId=sd00008014en_us&page=GUID-709AAADB-A9C1-40B6-AD22-958EE7E6F312.html>
- API e CLI Morpheus Data: <https://support.hpe.com/hpesc/public/docDisplay?docId=sd00008014en_us&page=GUID-F695DE83-0DF8-4C5E-A932-79B60E12C7B4.html>
- Repositórios no GitHub (HPE): <https://github.com/HewlettPackard/?q=morpheus&type=all&language=&sort=>
- Whitepapers e Relatórios: <https://www.hpe.com/us/en/resource-library.html/search/morpheus?type=whitepapers-and-reports>

### Bash & Ansible

- Guia de estilo Bash (Google): <https://google.github.io/styleguide/shellguide.html>
- Ansible Documentation & Best Practices: <https://docs.ansible.com/>
- Ansible Lint: <https://ansible.readthedocs.io/projects/lint/>
