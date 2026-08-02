# AI-INSTRUCTIONS.md

Este documento explica como evoluir as instruções para agentes de IA e GitHub Copilot neste repositório.

## Objetivo

Manter as instruções práticas, atualizadas e orientadas ao propósito do projeto:

- PoCs mínimas e verificáveis em Terraform para GCP
- apoio com Ansible quando necessário
- scripts auxiliares em Bash Linux

## Como evoluir as instruções

### 1) Comece pelo que já existe

Revise estes arquivos antes de propor mudanças:

- `AGENTS.md`
- `.github/instructions/terraform-gcp.instructions.md`
- `.github/instructions/ansible.instructions.md`
- `.github/instructions/bash-linux.instructions.md`
- `.github/instructions/readme-poc.instructions.md`
- `.github/prompts/create-gcp-terraform-poc.prompt.md`
- `.github/prompts/create-gcp-terraform-ansible-poc.prompt.md`
- `.github/prompts/create-gcp-terraform-ansible-poc-3phases.prompt.md`
- `.github/hooks/enforce-pocs-path.json`
- `scripts/hooks/enforce-path-standard.sh`

### 2) Escolha o tipo correto de customização

- **`AGENTS.md`**: regras globais do repositório
- **`.github/instructions/*.instructions.md`**: regras por tipo de arquivo (ex.: `*.tf`, `*.sh`, `*.yml`)
- **`.github/prompts/*.prompt.md`**: fluxos reutilizáveis para tarefas recorrentes
- **hooks/skills** (futuro): validações automáticas e automações por domínio

### 3) Critérios de qualidade para mudanças

Toda evolução deve ser:

- **curta e acionável** (sem texto genérico demais)
- **testável** (com comandos concretos de validação)
- **consistente** com `PoCs/<nome-da-poc>/`
- **alinhada a referências oficiais** (HashiCorp, GCP, Ansible, Bash)

### 4) Fluxo sugerido de atualização

1. Propor mudança pequena e específica.
2. Atualizar o(s) arquivo(s) de instrução.
3. Validar com uma POC exemplo (dry-run de scaffold).
4. Registrar no PR o que mudou e por quê.
5. Ajustar após feedback dos mantenedores.

## Skills recomendadas para apoiar este projeto

Abaixo estão skills úteis para criar e manter automações deste repositório.

### Skills de customização de agentes

- **`agent-customization`**
  - Para criar/ajustar `AGENTS.md`, `*.instructions.md`, `*.prompt.md`, skills e agentes customizados.

- **`chronicle`**
  - Para analisar histórico de sessões e identificar fricções recorrentes.

### Skills técnicas de Terraform/GCP úteis

- **`gcloud-auth-verification`**
  - Ajuda a resolver problemas de autenticação/ADC durante testes de PoCs.

- **`accidental-data-loss-prevention`**
  - Garante confirmação explícita antes de operações destrutivas.

## Skills que valem criar para este repositório (próximos passos)

1. **`poc-scaffold-terraform-gcp`**
   - Gera estrutura base em `PoCs/<nome>/` com `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `providers.tf` e README padronizado.

2. **`poc-readme-validator`**
   - Valida presença e ordem das 6 seções obrigatórias no `README.md` de cada POC.

3. **`terraform-quality-gate`**
   - Executa `terraform fmt`, `terraform validate` e checagens mínimas de `plan` antes de merge.

4. **`ansible-quality-gate`**
   - Executa `ansible-lint`, `--syntax-check` e `--check --diff` em PoCs com Ansible.

5. **`bash-quality-gate`**
   - Executa ShellCheck e valida padrões mínimos (`set -euo pipefail`, `--help`, checagem de dependências).

## Hooks e prompts implementados

- Hook de enforcement de caminho:
  - Arquivo: `.github/hooks/enforce-pocs-path.json`
  - Script: `scripts/hooks/enforce-path-standard.sh`
  - Objetivo: bloquear uso de `pocs/` e forçar padrão `PoCs/`.

- Prompt de scaffold Terraform + Ansible:
  - Arquivo: `.github/prompts/create-gcp-terraform-ansible-poc.prompt.md`
  - Objetivo: criar PoC mínima com Terraform, suporte opcional de Ansible e README padronizado.

## Roadmap recomendado

- Hook para validar seção obrigatória do `README.md` em cada PoC.
- Hook/automação para validar `terraform fmt`/`terraform validate` antes de merge.
- Prompt adicional para PoCs multiambiente (dev/stage/prod) com foco em baixo custo.

## Como usar esses recursos (guia rápido)

### Prompt direto (execução rápida)

- Arquivo: `.github/prompts/create-gcp-terraform-ansible-poc.prompt.md`
- Quando usar: tarefas curtas ou quando o escopo já está muito claro.

### Prompt em 3 fases (recomendado)

- Arquivo: `.github/prompts/create-gcp-terraform-ansible-poc-3phases.prompt.md`
- Quando usar: tarefas médias/longas, com necessidade de reduzir retrabalho.
- Como usar:
  1. Abra o prompt.
  2. Preencha os placeholders (`<nome-da-poc>`, `<objetivo-da-poc>`, `<regiao-gcp>`, `<servicos-gcp>`, `<usar-ansible>`, `<usa-scripts-bash>`).
  3. Execute e valide as 3 fases (diagnóstico → implementação → validação).

### Hook de padrão de caminho

- Arquivos:
  - `.github/hooks/enforce-pocs-path.json`
  - `scripts/hooks/enforce-path-standard.sh`
- Função: reforçar automaticamente o padrão de diretórios deste repositório.

## Governança de mudanças

- Mudanças de instruções devem passar revisão como qualquer código.
- Em caso de conflito entre documentos, `AGENTS.md` define a diretriz global.
- Evite duplicação: prefira referência cruzada entre arquivos.
