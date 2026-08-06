---
name: terraform-quality-gate
description: Executa validações de sintaxe, formatação, boas práticas e segurança em código Terraform para GCP e HPE Morpheus Data (HPE/hpe).
---

# Skill: Terraform Quality Gate

Esta skill fornece o checklist e comandos para auditoria de qualidade de manifestos Terraform GCP e HPE Morpheus Data.

---

## Quando Utilizar esta Skill

- Antes de finalizar ou propor alterações em arquivos `.tf`.
- Ao auditar código Terraform em `PoCs/<nome-da-poc>/`.

---

## Checklist de Validação

### 1. Formatação e Sintaxe
- Executar `terraform fmt -check` para garantir padronização.
- Executar `terraform validate` no diretório da POC.

### 2. Provedores e Versionamento
- GCP: Provedor `hashicorp/google`.
- HPE Morpheus Data: Provedor `HPE/hpe` (Registry: `https://registry.terraform.io/providers/HPE/hpe/latest`).
- Fixação de versão explícita nos blocos `terraform` e `required_providers` em `versions.tf`.

### 3. Padrões de Código e Nomenclatura
- Todos os identificadores em `snake_case`.
- Ausência de redundância no nome de recursos (evite `google_compute_instance.web_instance`, prefira `google_compute_instance.web`).

### 4. Variáveis e Outputs
- Toda variável em `variables.tf` possui `type` e `description`.
- Marcar `sensitive = true` para tokens de acesso Morpheus ou chaves de serviço GCP.
- Todo output em `outputs.tf` possui `description`.
- `terraform.tfvars` nunca commita credenciais (deve haver um `terraform.tfvars.example` com placeholders).

### 5. Segurança e Estado
- Nenhum `service_account_key` privada ou `access_token` hardcoded.
- Utilizar contas de serviço com escopo de privilégio mínimo.
- `.gitignore` configurado para ignorar `*.tfstate`, `*.tfstate.backup`, `.terraform/` e `*.tfvars` sensíveis.

---

## Comandos de Execução do Quality Gate

```bash
# Formatar código no padrão HashiCorp
terraform fmt -recursive

# Validar sintaxe e referências cruzadas
terraform validate

# Testar plano sem aplicar
terraform plan -var-file=terraform.tfvars.example
```
