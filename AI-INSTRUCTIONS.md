# AI-INSTRUCTIONS.md

Este documento explica como evoluir as instruções para agentes de IA e GitHub Copilot neste repositório.

## Objetivo

Manter as instruções práticas, atualizadas e orientadas ao propósito do projeto:

- PoCs mínimas e verificáveis em Terraform para GCP e Morpheus Data (via provedor `HPE/hpe`)
- Suporte à construção, diagnóstico, documentação e automações com Ansible baseando-se na coleção oficial `morpheus.core` (`ansible-collection-morpheus-core` da HPE)
- scripts auxiliares em Bash Linux

## Como evoluir as instruções

### 1) Comece pelo que já existe

Revise estes arquivos antes de propor mudanças:

- `AGENTS.md`
- `.agents/AGENTS.md`
- `.github/copilot-instructions.md`
- `.github/instructions/terraform-gcp.instructions.md`
- `.github/instructions/terraform-hpe-morpheus.instructions.md`
- `.github/instructions/ansible.instructions.md`
- `.github/instructions/bash-linux.instructions.md`
- `.github/instructions/readme-poc.instructions.md`
- `.github/prompts/create-gcp-terraform-poc.prompt.md`
- `.github/prompts/create-gcp-terraform-ansible-poc.prompt.md`
- `.github/prompts/create-gcp-terraform-ansible-poc-3phases.prompt.md`
- `.github/hooks/enforce-pocs-path.json`
- `scripts/hooks/enforce-path-standard.sh`

### 2) Escolha o tipo correto de customização

- **`AGENTS.md` e `.agents/AGENTS.md`**: regras globais do repositório para Agentes de IA
- **`.github/copilot-instructions.md`**: instruções principais do repositório para GitHub Copilot
- **`.github/instructions/*.instructions.md`**: regras por tipo de arquivo para GitHub Copilot (ex.: `*.tf`, `*.sh`, `*.yml`)
- **`.github/prompts/*.prompt.md`**: fluxos reutilizáveis para tarefas recorrentes
- **`.agents/skills/*/SKILL.md`**: skills especializadas para automações e quality gates

### 3) Documentação Oficial do Morpheus Data (HPE)

Para assistências relativas a Morpheus Data, provedor HPE Terraform, coleção Ansible, API, CLI e Console Web, utilize as seguintes fontes oficiais:

- **Provedor Terraform HPE**: <https://registry.terraform.io/providers/HPE/hpe/latest>
- **Coleção Ansible Morpheus Core (HPE)**: <https://github.com/HewlettPackard/ansible-collection-morpheus-core>
- **Configurações da solução e uso da console web**: <https://support.hpe.com/hpesc/public/docDisplay?docId=sd00008014en_us&page=GUID-709AAADB-A9C1-40B6-AD22-958EE7E6F312.html>
- **API e CLI**: <https://support.hpe.com/hpesc/public/docDisplay?docId=sd00008014en_us&page=GUID-F695DE83-0DF8-4C5E-A932-79B60E12C7B4.html>
- **Repositórios no GitHub (HPE)**: <https://github.com/HewlettPackard/?q=morpheus&type=all&language=&sort=>
- **Whitepapers e Relatórios**: <https://www.hpe.com/us/en/resource-library.html/search/morpheus?type=whitepapers-and-reports>

### 4) Critérios de qualidade para mudanças

Toda evolução deve ser:

- **redigida em Português do Brasil (pt-BR)** para toda documentação e manuais
- **validada via Markdown Lint** (`markdownlint` ou `pymarkdown scan`) em arquivos `.md`
- **curta e acionável** (sem texto genérico demais)
- **testável** (com comandos concretos de validação)
- **consistente** com `PoCs/<nome-da-poc>/`
- **alinhada a referências oficiais** (HashiCorp, GCP, HPE Morpheus Terraform & Ansible, Bash)

### 5) Fluxo sugerido de atualização

1. Propor mudança pequena e específica.
2. Atualizar o(s) arquivo(s) de instrução.
3. Validar com uma POC exemplo (dry-run de scaffold).
4. Registrar no PR o que mudou e por quê.
5. Ajustar após feedback dos mantenedores.

## Skills recomendadas para apoiar este projeto

Abaixo estão skills úteis para criar e manter automações deste repositório dispostas em `.agents/skills/`:

- `poc-scaffold`
- `poc-readme-validator`
- `terraform-quality-gate`
- `ansible-quality-gate`
- `bash-quality-gate`

## Governança de mudanças

- Mudanças de instruções devem passar revisão como qualquer código.
- Em caso de conflito entre documentos, `AGENTS.md` define a diretriz global.
- Evite duplicação: prefira referência cruzada entre arquivos.
