---
applyTo: "**/*.{yml,yaml}"
description: "Padrões para playbooks, inventários, roles e coleções Ansible nas PoCs"
---

# Ansible — Regras do repositório

Estas regras se aplicam a playbooks, roles e estruturas Ansible usadas nas PoCs deste repositório, incluindo automações gerais e integrações com Morpheus Data via coleção oficial da HPE.

## Resultado esperado

- Automação simples, legível e idempotente.
- Suporte completo para **construção, diagnóstico e documentação** de automações Ansible.
- Para interações com Morpheus Data, adotar como base a coleção oficial [`morpheus.core`](https://github.com/HewlettPackard/ansible-collection-morpheus-core) disponibilizada pela HPE.
- Uso de Ansible como apoio à comprovação da POC (bootstrap/configuração e orquestração), sem inflar complexidade.
- Execução previsível para analista júnior.

## Estrutura recomendada

Quando Ansible for usado em uma POC, organize da seguinte forma:

- `PoCs/<nome-da-poc>/ansible/`
  - `requirements.yml` (declaração de dependências de coleções, ex.: `morpheus.core`)
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

### Exemplo de `requirements.yml`

```yaml
---
collections:
  - name: morpheus.core
    # version: ">=0.6.0"
```

## Construção com Ansible e Coleção HPE Morpheus Core

- Utilize os módulos fornecidos pela coleção `morpheus.core` para gerenciar recursos no Morpheus Data (instâncias, apps, blueprints, tasks, workflows, inventários dinâmicos, etc.).
- Declare explicitamente os FQCNs (Fully Qualified Collection Names) nas tasks (ex.: `morpheus.core.instance`, `morpheus.core.workflow`, `morpheus.core.task`).
- Separe lógicas reutilizáveis em roles dedicadas.

## Diagnóstico e Troubleshooting

Ao diagnosticar problemas em execuções Ansible ou integrações com Morpheus:

- Verifique a conectividade com o endpoint Morpheus (`MORPHEUS_API_URL`) e validade do token (`MORPHEUS_API_TOKEN` ou `MORPHEUS_ACCESS_TOKEN`).
- Em falhas de API, execute com modo de depuração ativado (`ansible-playbook -vvv`) para inspecionar payload, headers HTTP e respostas de erro.
- Trate timeouts e certificados customizados (`validate_certs: false` somente se devidamente documentado para ambientes laboratoriais).

## Convenções obrigatórias

- Todas as tasks devem ter `name` descritivo.
- Priorize módulos nativos do Ansible e módulos oficiais da coleção `morpheus.core` em vez de `shell`/`command` ou chamadas `uri` manuais.
- Quando `shell`/`command` forem inevitáveis, documente o motivo no playbook e adicione `changed_when`.
- Evite `ignore_errors: true` sem justificativa explícita.
- Segredos não devem ser hardcoded em playbooks/vars.

## Idempotência e segurança

- Tasks devem ser idempotentes por padrão.
- Use handlers para reinícios/reloads somente quando houver mudança.
- Evite mudanças destrutivas sem validação explícita.
- Prefira `become: true` apenas em escopos mínimos necessários.
- Credenciais e tokens de acesso devem ser injetados via variáveis de ambiente ou Ansible Vault.

## Validação

Antes de propor merge, executar quando aplicável:

- `ansible-galaxy collection install -r requirements.yml` (se houver `requirements.yml`)
- `ansible-lint`
- `ansible-playbook --syntax-check`
- `ansible-playbook --check --diff`

## Documentação mínima em README da POC

Quando a POC usar Ansible, o README da POC deve incluir:

- Como instalar dependências (`ansible-galaxy collection install -r requirements.yml`).
- Como executar o playbook (com inventário).
- Variáveis de ambiente ou credenciais necessárias (ex.: `MORPHEUS_API_URL`, `MORPHEUS_API_TOKEN`).
- Como validar que a configuração foi aplicada.
- Como reverter/descomissionar o que foi aplicado.

## Referências

- Documentação Oficial da Coleção Ansible Morpheus Core (HPE): <https://github.com/HewlettPackard/ansible-collection-morpheus-core>
- Ansible Documentation & Best Practices: <https://docs.ansible.com/>
- Ansible Tips & Tricks: <https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html>
- Ansible Lint: <https://ansible.readthedocs.io/projects/lint/>
