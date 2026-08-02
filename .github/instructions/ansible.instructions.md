---
applyTo: "**/*.{yml,yaml}"
description: "Padrões para playbooks, inventários e roles Ansible nas PoCs"
---

# Ansible — Regras do repositório

Estas regras se aplicam a playbooks e estruturas Ansible usadas nas PoCs deste repositório.

## Resultado esperado

- Automação simples, legível e idempotente.
- Uso de Ansible como apoio à comprovação da POC (bootstrap/configuração), sem inflar complexidade.
- Execução previsível para analista júnior.

## Estrutura recomendada

Quando Ansible for usado em uma POC, prefira esta organização:

- `PoCs/<nome-da-poc>/ansible/`
  - `site.yml` (ou playbook principal)
  - `inventories/`
    - `dev/hosts.yml`
  - `group_vars/`
  - `host_vars/`
  - `roles/`
    - `<nome_role>/tasks/main.yml`
    - `<nome_role>/handlers/main.yml`
    - `<nome_role>/defaults/main.yml`
    - `<nome_role>/templates/` e `files/` (quando necessário)

## Convenções obrigatórias

- Todas as tasks devem ter `name` descritivo.
- Priorize módulos nativos do Ansible em vez de `shell`/`command`.
- Quando `shell`/`command` forem inevitáveis, documente o motivo no playbook.
- Evite `ignore_errors: true` sem justificativa explícita.
- Segredos não devem ser hardcoded em playbooks/vars.

## Idempotência e segurança

- Tasks devem ser idempotentes por padrão.
- Use handlers para reinícios/reloads somente quando houver mudança.
- Evite mudanças destrutivas sem validação explícita.
- Prefira `become: true` apenas em escopos mínimos necessários.

## Validação

Antes de propor merge, executar quando aplicável:

- `ansible-lint`
- `ansible-playbook --syntax-check`
- `ansible-playbook --check --diff`

## Documentação mínima em README da POC

Quando a POC usar Ansible, o README da POC deve incluir:

- Como executar o playbook (com inventário).
- Pré-requisitos (versão do Ansible e coleções necessárias).
- Como validar que a configuração foi aplicada.
- Como reverter/descomissionar o que foi aplicado.

## Referências

- https://docs.ansible.com/
- https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html
- https://ansible.readthedocs.io/projects/lint/
