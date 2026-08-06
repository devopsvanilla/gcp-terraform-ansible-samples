---
name: poc-scaffold
description: Automatiza a criação ou refatoração de Provas de Conceito (POCs) em Terraform GCP e Ansible opcional no padrão PoCs/<nome-da-poc>/ em 3 fases.
---

# Skill: POC Scaffold (GCP Terraform + Ansible)

Esta skill orienta a criação ou evolução de Provas de Conceito (POCs) no repositório mantendo o padrão estrito de diretórios e boas práticas.

---

## Quando Utilizar esta Skill

- Ao criar uma nova POC do zero no repositório.
- Ao evoluir ou reestruturar uma POC existente em `PoCs/<nome-da-poc>/`.
- Quando o usuário solicitar a criação de recursos na GCP usando Terraform e/ou Ansible.

---

## Diretrizes de Scaffold

### 1. Padrão de Diretórios
- Todo código deve residir obrigatoriamente dentro de `PoCs/<nome-da-poc>/`.
- **Importante**: O prefixo do diretório pai deve ser exatamente `PoCs/` (com 'P' maiúsculo e 'C' maiúsculo).
- Estrutura base de uma POC:
  ```text
  PoCs/<nome-da-poc>/
  ├── main.tf
  ├── variables.tf
  ├── outputs.tf
  ├── versions.tf
  ├── providers.tf
  ├── terraform.tfvars.example
  ├── README.md
  ├── ansible/            # (opcional: quando a POC utilizar Ansible)
  │   ├── site.yml
  │   ├── inventories/
  │   ├── group_vars/
  │   └── roles/
  └── scripts/            # (opcional: scripts bash auxiliares)
  ```

---

## Execução em 3 Fases

### Fase 1: Diagnóstico e Planejamento
1. Verifique se o diretório `PoCs/<nome-da-poc>` já existe e inspecione seus arquivos.
2. Identifique os serviços da GCP a serem provisionados (`Compute Engine`, `VPC`, `GCS`, `IAM`, etc.).
3. Determine se haverá suporte a Ansible para bootstrap ou configuração da aplicação.
4. Apresente um plano resumido ao usuário antes de alterar código.

### Fase 2: Implementação
1. **Terraform**:
   - Crie `versions.tf` fixando a versão mínima do Terraform e do provider `hashicorp/google`.
   - Crie `providers.tf` parametrizando `project`, `region` e `zone`.
   - Crie `variables.tf` com `type` e `description` em todas as variáveis.
   - Crie `main.tf` utilizando recursos oficiais da GCP de baixo custo.
   - Crie `outputs.tf` exposto dados úteis (IPs, URIs, IDs).
   - Forneça um `terraform.tfvars.example` com valores de exemplo seguros.

2. **Ansible** (se selecionado):
   - Estruture em `PoCs/<nome-da-poc>/ansible/`.
   - Crie playbooks idempotentes com nomes descritivos nas tasks.

3. **Bash Scripts** (se aplicável):
   - Garanta `#!/usr/bin/env bash`, `set -euo pipefail` e suporte a `--help`.

4. **Documentação**:
   - Crie `PoCs/<nome-da-poc>/README.md` com as 6 seções obrigatórias.
   - Atualize `/README.md` na raiz com o link e descrição da nova POC no índice.

### Fase 3: Validação
1. Execute `terraform fmt` e `terraform validate`.
2. Execute `ansible-lint` e `--syntax-check` se Ansible foi incluído.
3. Garanta que nenhuma credencial ou segredo foi commitado.
