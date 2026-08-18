---
name: ansible-quality-gate
description: Executa checagens de sintaxe, idempotência, coleções (como morpheus.core) e boas práticas para playbooks, inventários e roles Ansible nas POCs.
---

# Skill: Ansible Quality Gate

Esta skill estabelece o processo de validação de qualidade, segurança, construção e diagnóstico para código Ansible utilizado no repositório, incluindo automações de infraestrutura e integrações com a plataforma HPE Morpheus Data.

---

## Quando Utilizar esta Skill

- Ao criar ou modificar playbooks, roles, inventários e `requirements.yml` em `PoCs/<nome-da-poc>/ansible/`.
- Ao construir ou diagnosticar automações que utilizam a coleção oficial [`morpheus.core`](https://github.com/HewlettPackard/ansible-collection-morpheus-core) da HPE.
- Antes de indicar a POC como pronta para execução.

---

## Checklist de Validação

### 1. Estrutura e Organização
- Playbooks situados em `PoCs/<nome-da-poc>/ansible/`.
- Arquivo `requirements.yml` declarando dependências de coleções (ex.: `morpheus.core`) quando aplicável.
- Inventários organizados sob `inventories/`.
- Variáveis agrupadas em `group_vars/` ou `host_vars/`.
- Roles estruturadas com subdiretórios padrão (`tasks`, `handlers`, `defaults`, `templates`).

### 2. Qualidade, Idempotência e Coleção HPE Morpheus
- Toda task deve ter uma propriedade `name` descritiva em português ou inglês.
- Priorizar módulos nativos do Ansible e módulos oficiais da coleção `morpheus.core` (`morpheus.core.<modulo>`).
- Se usar `command` ou `shell`, documentar o motivo e adicionar `changed_when` ou `creates` para manter a idempotência.
- Tratar reinícios de serviços obrigatoriamente através de `handlers` ativados por `notify`.

### 3. Segurança e Credenciais
- Nenhuma chave privada SSH, token de API (`MORPHEUS_API_TOKEN`) ou senha hardcoded em playbooks/vars.
- Usar variáveis de ambiente seguras ou Ansible Vault para credenciais.
- Usar `become: true` estritamente onde permissões root forem necessárias.

---

## Comandos de Verificação

```bash
# Instalar coleções declaradas (ex.: morpheus.core)
ansible-galaxy collection install -r requirements.yml

# Validar sintaxe da playbook
ansible-playbook --syntax-check site.yml -i inventories/dev/hosts.yml

# Executar ansible-lint se instalado
ansible-lint site.yml

# Simular execução sem aplicar alterações (dry-run)
ansible-playbook --check --diff site.yml -i inventories/dev/hosts.yml
```

