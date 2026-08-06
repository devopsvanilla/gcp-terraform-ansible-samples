---
name: ansible-quality-gate
description: Executa checagens de sintaxe, idempotência e boas práticas para playbooks, inventários e roles Ansible nas POCs.
---

# Skill: Ansible Quality Gate

Esta skill estabelece o processo de validação de qualidade e segurança para código Ansible utilizado no repositório.

---

## Quando Utilizar esta Skill

- Ao criar ou modificar playbooks e roles em `PoCs/<nome-da-poc>/ansible/`.
- Antes de indicar a POC como pronta para execução.

---

## Checklist de Validação

### 1. Estrutura e Organização
- Playbooks situados em `PoCs/<nome-da-poc>/ansible/`.
- Inventários organizados sob `inventories/`.
- Variáveis agrupadas em `group_vars/` ou `host_vars/`.
- Roles estruturadas com subdiretórios padrão (`tasks`, `handlers`, `defaults`, `templates`).

### 2. Qualidade e Idempotência
- Toda task deve ter uma propriedade `name` descritiva em português ou inglês.
- Preferir módulos nativos do Ansible (`apt`, `copy`, `template`, `systemd`, etc.) em vez de usar `command` ou `shell`.
- Se usar `command` ou `shell`, documentar o motivo e adicionar `changed_when` ou `creates` para manter a idempotência.
- Tratar reinícios de serviços obrigatoriamente através de `handlers` ativados por `notify`.

### 3. Segurança
- Nenhuma chave privada SSH, token de API ou senha hardcoded em playbooks/vars.
- Usar `become: true` estritamente onde permissões root forem necessárias.

---

## Comandos de Verificação

```bash
# Validar sintaxe da playbook
ansible-playbook --syntax-check site.yml -i inventories/dev/hosts.yml

# Executar ansible-lint se instalado
ansible-lint site.yml

# Simular execução sem aplicar alterações (dry-run)
ansible-playbook --check --diff site.yml -i inventories/dev/hosts.yml
```
