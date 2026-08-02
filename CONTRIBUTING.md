# CONTRIBUTING.md

Obrigado por contribuir com este repositório! 🎯

Este projeto é focado em **PoCs mínimas e verificáveis** para Terraform na GCP, com apoio opcional de Ansible e scripts Bash Linux.

## Como contribuir

1. Faça um fork (se aplicável) e crie uma branch curta:
   - `feature/<tema>`
   - `fix/<tema>`
   - `docs/<tema>`
2. Implemente mudanças pequenas, objetivas e testáveis.
3. Execute as validações locais.
4. Abra PR com contexto claro e evidências de validação.

## Estrutura esperada para novas PoCs

Cada POC deve ficar em um diretório próprio:

- `PoCs/<nome-da-poc>/`

Estrutura sugerida (ajuste conforme necessidade da POC):

- `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `providers.tf`
- `README.md`
- `ansible/` (opcional)
- `scripts/` (opcional)
- `helpers/` (opcional)
- `files/` e `templates/` (quando aplicável)

## Regras obrigatórias de documentação

### README da POC

O `README.md` de cada POC deve conter **exatamente** estas seções (nesta ordem):

1. O que será implantado
2. Pré-requisitos
3. Como implantar
4. Como conferir a implantação
5. Como descomissionar
6. Guia de erros comuns

### README da raiz

O `README.md` da raiz deve manter o propósito do projeto e o índice das PoCs.

## Qualidade e validação

### Terraform

- `terraform fmt`
- `terraform validate`
- revisão de `terraform plan`

Boas práticas:

- declarar variáveis e outputs com descrição
- fixar versões de Terraform/provider
- não commitar estado local e arquivos sensíveis

### Ansible (quando usado)

- `ansible-lint`
- `ansible-playbook --syntax-check`
- `ansible-playbook --check --diff`

Boas práticas:

- tasks com `name` descritivo
- preferência por módulos nativos
- idempotência

### Bash (quando usado)

- `shellcheck`

Boas práticas:

- `#!/usr/bin/env bash`
- `set -euo pipefail`
- `--help`, validação de argumentos e de dependências

## Segurança

- Nunca commitar segredos, credenciais, chaves privadas ou `*.tfvars` sensíveis.
- Evite operações destrutivas sem documentação explícita.

## Hook de padrão de diretório

Este repositório possui um hook para reforçar o padrão de caminho das PoCs:

- `.github/hooks/enforce-pocs-path.json`
- `scripts/hooks/enforce-path-standard.sh`

O hook bloqueia operações que tentem usar `pocs/` e exige `PoCs/`.

## Prompts de scaffold disponíveis

- `.github/prompts/create-gcp-terraform-poc.prompt.md`
  - Scaffold de POC Terraform para GCP.
- `.github/prompts/create-gcp-terraform-ansible-poc.prompt.md`
  - Scaffold de POC Terraform para GCP com apoio opcional de Ansible.
- `.github/prompts/create-gcp-terraform-ansible-poc-3phases.prompt.md`
  - Versão guiada em 3 fases (diagnóstico, implementação e validação) com placeholders.

### Como usar no dia a dia

1. Para tarefas curtas, use o prompt direto de scaffold.
2. Para tarefas médias/longas, prefira o prompt `3phases`.
3. Preencha os placeholders antes de executar (diretório da PoC, nome, objetivo, região e serviços GCP).
4. Garanta que o resultado final respeita o padrão de diretórios definido no repositório.

## Checklist para PR

Antes de abrir PR, confirme:

- [ ] Diretório da POC segue `PoCs/<nome-da-poc>/`
- [ ] README da POC possui as 6 seções obrigatórias
- [ ] Terraform formatado e validado
- [ ] Ansible/Bash validados (quando aplicável)
- [ ] Evidências de teste adicionadas na descrição do PR
- [ ] Sem segredos em arquivos versionados
- [ ] Sem uso de caminho legado `pocs/`

## Referências

- Terraform Style Guide: <https://developer.hashicorp.com/terraform/language/style>
- Terraform on Google Cloud: <https://docs.cloud.google.com/docs/terraform>
- GCP Terraform Best Practices: <https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure>
- Ansible Docs: <https://docs.ansible.com/>
- Ansible Lint: <https://ansible.readthedocs.io/projects/lint/>
- Bash Style Guide: <https://google.github.io/styleguide/shellguide.html>
- ShellCheck: <https://www.shellcheck.net/>
