---
applyTo: "**/*.tf"
description: "Padrões para manifestos Terraform na GCP neste repositório de POCs"
---

# Terraform (GCP) — Regras do repositório

Use estas regras para qualquer arquivo Terraform deste repositório.

## Resultado esperado

- Implementar POCs pequenas, com validação objetiva.
- Preferir recursos de baixo custo e fácil limpeza.
- Manter código legível, previsível e testável.

## Estrutura e organização

- Em POCs, prefira separar por intenção:
  - `versions.tf` (required_version e required_providers)
  - `providers.tf`
  - `main.tf`
  - `variables.tf`
  - `outputs.tf`
- Evite mega-arquivos; agrupe por domínio quando necessário (ex.: `network.tf`, `iam.tf`).
- Para módulos reutilizáveis, não configure backend dentro do módulo.

## Convenções obrigatórias

- Use nomes em `snake_case` para identificadores Terraform.
- Não repetir tipo no nome lógico do recurso (evite `main_instance` quando `main` basta).
- Toda variável deve ter:
  - `type`
  - `description`
  - `default` apenas quando fizer sentido
- Todo output deve ter:
  - `description`
  - valor derivado de recurso/módulo (evitar pass-through desnecessário de variável)
- Fixar versões de provider/terraform de forma explícita.

## GCP-specific

- Quando necessário, declarar e documentar APIs exigidas.
- Preferir módulos/recursos oficiais e fontes de dados para descobrir estado atual.
- Explicitar `project_id`, `region` e `zone` conforme o escopo da POC.

## Segurança e estado

- Nunca armazenar credenciais hardcoded em `.tf`.
- Não versionar estado local ou artefatos sensíveis.
- Para recursos stateful, avaliar `lifecycle { prevent_destroy = true }` quando apropriado.

## Fluxo de validação (antes de propor merge)

- `terraform fmt`
- `terraform validate`
- `terraform plan` revisado

## Referências

- https://developer.hashicorp.com/terraform/language/style
- https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure
- https://docs.cloud.google.com/docs/terraform/best-practices/root-modules
- https://docs.cloud.google.com/docs/terraform/best-practices/reusable-modules
