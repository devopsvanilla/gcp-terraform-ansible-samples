# AGENTS.md

## Objetivo deste repositório

Este repositório é dedicado a **provas de conceito (POCs) em Terraform para GCP** e scripts auxiliares em **Bash Linux**.

As POCs devem implantar **unidades mínimas de software ou configuração** que comprovem funcionamento com baixo custo/complexidade.

## Escopo para agentes de IA e Copilot

Ao criar ou alterar conteúdo neste repositório, siga estas regras:

1. **Foque em POCs mínimas e verificáveis**

   - Cada POC deve ser pequena, objetiva e com validação clara.

2. **Uma POC por diretório próprio**

   - Use o padrão: `PoCs/<nome-da-poc>/`.

3. **README obrigatório por POC**

   - Cada `PoCs/<nome-da-poc>/README.md` deve conter exatamente estas seções:
     - O que será implantado
     - Pré-requisitos
     - Como implantar
     - Como conferir a implantação
     - Como descomissionar
     - Guia de erros comuns

4. **README raiz obrigatório**

   - O `README.md` da raiz deve descrever o propósito do projeto e funcionar como índice das POCs.

5. **Terraform com boas práticas**

   - Formatação e validação antes de propor mudanças.
   - Variáveis e outputs sempre documentados.
   - Versionamento de provider/terraform explícito.

6. **Ansible com boas práticas**

   - Playbooks e roles devem ser idempotentes.
   - Inventários e variáveis por ambiente devem ser separados e documentados.
   - Validar com `ansible-lint` antes de propor mudanças.

7. **Scripts preferencialmente em Bash Linux**

   - Scripts idempotentes, com tratamento de erro e ajuda de uso.

8. **Use os artefatos de automação do repositório**

  Hook de política: `.github/hooks/enforce-pocs-path.json` + `scripts/hooks/enforce-path-standard.sh`.
  Prompts de scaffold: `.github/prompts/create-gcp-terraform-poc.prompt.md` e `.github/prompts/create-gcp-terraform-ansible-poc.prompt.md`.

## Estrutura recomendada

- `PoCs/<nome-da-poc>/`
  - `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `providers.tf` (conforme necessidade)
  - `README.md` (com as seções obrigatórias)
  - `ansible/` (opcional: playbooks e roles de configuração)
  - `scripts/` (opcional: scripts chamados pelo Terraform)
  - `helpers/` (opcional: scripts de apoio operacional)
  - `files/` e `templates/` (quando aplicável)

## Convenções de qualidade

- Terraform:
  - Execute `terraform fmt`, `terraform validate` e revisão de `terraform plan`.
  - Não commitar `terraform.tfstate*`, `.terraform/` e segredos em `*.tfvars`.
- Bash:
  - Use `#!/usr/bin/env bash` e `set -euo pipefail`.
  - Prefira `[[ ... ]]`, quote em variáveis (`"${var}"`), funções pequenas e `main`.
  - Validar com ShellCheck quando possível.
- Ansible:
  - Padronize diretórios em `inventories/`, `group_vars/`, `host_vars/`, `roles/` e playbooks.
  - Use nomes descritivos em tasks e handlers.
  - Priorize módulos nativos em vez de `shell`/`command` quando possível.
  - Use `--check` e `--diff` para validação quando aplicável.

## Referências oficiais (linkar, não copiar)

- Terraform Style Guide (HashiCorp):
  - <https://developer.hashicorp.com/terraform/language/style>
- Terraform Tests (HashiCorp):
  - <https://developer.hashicorp.com/terraform/language/tests>
- Terraform no Google Cloud (overview):
  - <https://docs.cloud.google.com/docs/terraform>
- Boas práticas Terraform na GCP (general style/structure):
  - <https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure>
- Boas práticas de root modules na GCP:
  - <https://docs.cloud.google.com/docs/terraform/best-practices/root-modules>
- Boas práticas de reusable modules na GCP:
  - <https://docs.cloud.google.com/docs/terraform/best-practices/reusable-modules>
- Guia de estilo Bash (Google):
  - <https://google.github.io/styleguide/shellguide.html>
- ShellCheck:
  - <https://www.shellcheck.net/>
- Ansible Documentation:
  - <https://docs.ansible.com/>
- Ansible Best Practices:
  - <https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html>
- Ansible Lint:
  - <https://ansible.readthedocs.io/projects/lint/>

## Nota de colaboração

Se houver qualquer ambiguidade de estrutura, priorize:

1) legibilidade,
2) segurança,
3) custo baixo,
4) facilidade de destruição limpa (`terraform destroy`).
