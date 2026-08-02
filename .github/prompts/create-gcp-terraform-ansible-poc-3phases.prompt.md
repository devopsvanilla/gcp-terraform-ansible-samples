---
mode: "agent"
description: "Scaffold de PoC GCP em 3 fases (diagnóstico, implementação, validação) com Terraform e Ansible opcional"
---

Use este prompt para criar ou evoluir uma PoC usando o padrão de diretório definido no repositório, com execução em 3 fases.

## Placeholders (preencha antes de executar)

- `<diretorio-da-poc>`: caminho da pasta da PoC conforme padrão do repositório
- `<nome-da-poc>`: nome lógico da PoC
- `<objetivo-da-poc>`: o que a PoC comprova
- `<regiao-gcp>`: região principal (ex.: `us-central1`)
- `<servicos-gcp>`: recursos principais (ex.: `Compute Engine, VPC`)
- `<usar-ansible>`: `sim` ou `nao`
- `<usa-scripts-bash>`: `sim` ou `nao`

## Contexto da solicitação

Crie/evolua a PoC `<nome-da-poc>` no diretório `<diretorio-da-poc>` com objetivo: `<objetivo-da-poc>`, na região `<regiao-gcp>`, usando `<servicos-gcp>`.  
Ansible: `<usar-ansible>`. Scripts Bash: `<usa-scripts-bash>`.

## Fase 1 — Diagnóstico (não implementar ainda)

1. Inspecione o que já existe em `<diretorio-da-poc>`.
2. Liste lacunas para concluir a PoC mínima e verificável:
   - Terraform (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `providers.tf` quando aplicável)
   - `README.md` da PoC com seções obrigatórias:
     - O que será implantado
     - Pré-requisitos
     - Como implantar
     - Como conferir a implantação
     - Como descomissionar
     - Guia de erros comuns
   - Ansible opcional (`<diretorio-da-poc>/ansible/`)
   - Scripts Bash opcionais (`set -euo pipefail`, `--help`)
3. Proponha plano curto, em passos pequenos e verificáveis.

## Fase 2 — Implementação

Implemente o plano com mudanças pequenas:

- Mantenha o padrão de diretório definido no repositório.
- Terraform com boas práticas: nomes claros, variáveis/outputs documentados, sem segredos hardcoded.
- Se Ansible = `sim`:
  - usar `<diretorio-da-poc>/ansible/`
  - tasks com `name` descritivo e idempotência
  - priorizar módulos nativos
- Se scripts Bash = `sim`:
  - `#!/usr/bin/env bash`
  - `set -euo pipefail`
  - validação de argumentos/dependências e `--help`
- Atualize o `README.md` raiz com índice da PoC.

## Fase 3 — Validação e fechamento

1. Rode e reporte validações aplicáveis:
   - Terraform: `terraform fmt`, `terraform validate`, revisão de `terraform plan`
   - Ansible (se usado): `ansible-lint`, `ansible-playbook --syntax-check`, `ansible-playbook --check --diff`
   - Bash (se usado): `shellcheck`
2. Liste arquivos alterados e propósito de cada um.
3. Entregue resumo final com:
   - o que foi criado/ajustado
   - como reproduzir
   - limitações/custos esperados
   - próximos passos sugeridos

## Regras de qualidade

- A PoC deve ser mínima, de baixo custo e fácil de descomissionar.
- Estrutura consistente com o padrão deste repositório.
- Evitar ambiguidade: sempre incluir critérios concretos de validação.

## Referências

- Terraform Style Guide: <https://developer.hashicorp.com/terraform/language/style>
- Terraform Tests: <https://developer.hashicorp.com/terraform/language/tests>
- Terraform on Google Cloud: <https://docs.cloud.google.com/docs/terraform>
- GCP Terraform Best Practices: <https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure>
- Ansible Docs: <https://docs.ansible.com/>
- Ansible Lint: <https://ansible.readthedocs.io/projects/lint/>
- Bash Style Guide: <https://google.github.io/styleguide/shellguide.html>
- ShellCheck: <https://www.shellcheck.net/>
