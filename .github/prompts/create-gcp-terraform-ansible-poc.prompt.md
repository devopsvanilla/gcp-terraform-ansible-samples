---
mode: "agent"
description: "Cria uma POC mínima em Terraform para GCP com apoio opcional de Ansible e documentação padronizada"
---

Crie uma nova POC em `PoCs/<nome-da-poc>/` para Terraform na GCP, com possibilidade de usar Ansible para bootstrap/configuração, mantendo baixo custo e validação objetiva.

## Requisitos obrigatórios

1. Criar diretório próprio da POC.
2. Criar Terraform com boas práticas (`main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `providers.tf` quando aplicável).
3. Criar `README.md` da POC com as seções obrigatórias:
   - O que será implantado
   - Pré-requisitos
   - Como implantar
   - Como conferir a implantação
   - Como descomissionar
   - Guia de erros comuns
4. Se houver Ansible:
   - usar `PoCs/<nome-da-poc>/ansible/`
   - manter tasks idempotentes e com `name` descritivo
   - priorizar módulos nativos
   - incluir instruções de execução e validação no README da POC
5. Se houver scripts auxiliares:
   - usar Bash Linux com `set -euo pipefail`
   - fornecer `--help`
   - validar dependências (`terraform`, `gcloud`, `ansible`, etc.)
6. Atualizar o `README.md` da raiz com índice da nova POC.

## Validações esperadas

- Terraform: `terraform fmt`, `terraform validate`, revisão de `terraform plan`
- Ansible (quando usado): `ansible-lint`, `ansible-playbook --syntax-check`, `ansible-playbook --check --diff`
- Bash (quando usado): `shellcheck`

## Critérios de qualidade

- POC mínima e reproduzível por analista júnior.
- Sem segredos hardcoded.
- Comandos claros para implantação, validação e descomissionamento.
- Estrutura consistente com padrão `PoCs/`.

## Referências

- Terraform Style Guide: <https://developer.hashicorp.com/terraform/language/style>
- Terraform Tests: <https://developer.hashicorp.com/terraform/language/tests>
- Terraform on Google Cloud: <https://docs.cloud.google.com/docs/terraform>
- GCP Terraform Best Practices: <https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure>
- Ansible Docs: <https://docs.ansible.com/>
- Ansible Lint: <https://ansible.readthedocs.io/projects/lint/>
- Bash Style Guide: <https://google.github.io/styleguide/shellguide.html>
- ShellCheck: <https://www.shellcheck.net/>
