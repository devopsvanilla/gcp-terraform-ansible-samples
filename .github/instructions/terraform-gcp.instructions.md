---
applyTo: "**/*.tf"
description: "Padrões para manifestos Terraform na GCP e HPE Morpheus Data neste repositório de POCs"
---

# Terraform (GCP & HPE Morpheus Data) — Regras do repositório

Use estas regras para qualquer arquivo Terraform deste repositório.

## Resultado esperado

- Implementar POCs pequenas, com validação objetiva.
- Preferir recursos de baixo custo e fácil limpeza (`terraform destroy`).
- Suportar provisionamento em **Google Cloud Platform (GCP)** e automações no **Morpheus Data** via provedor oficial HPE (`HPE/hpe`).
- Manter código legível, previsível e testável.

## Estrutura e organização

- Em POCs, prefira separar por intenção:
  - `versions.tf` (required_version e required_providers: `hashicorp/google` e/ou `HPE/hpe`)
  - `providers.tf`
  - `main.tf`
  - `variables.tf`
  - `outputs.tf`
- Evite mega-arquivos; agrupe por domínio quando necessário (ex.: `network.tf`, `iam.tf`, `morpheus_tasks.tf`).
- Para módulos reutilizáveis, não configure backend dentro do módulo.

## Convenções obrigatórias

- Use nomes em `snake_case` para identificadores Terraform.
- Não repetir tipo no nome lógico do recurso (evite `main_instance` quando `main` basta).
- Toda variável deve ter:
  - `type`
  - `description`
  - `default` apenas quando fizer sentido
  - `sensitive = true` para tokens/credenciais
- Todo output deve ter:
  - `description`
  - valor derivado de recurso/módulo (evitar pass-through desnecessário de variável)
- Fixar versões de provider/terraform de forma explícita.

## Provedores e Referências Oficiais

### Google Cloud Platform (GCP)
- Explicitar `project_id`, `region` e `zone` conforme o escopo da POC.
- Referência: <https://docs.cloud.google.com/docs/terraform>

### HPE Morpheus Data
- Provedor oficial: `HPE/hpe` (<https://registry.terraform.io/providers/HPE/hpe/latest>)
- Console Web e Configurações: <https://support.hpe.com/hpesc/public/docDisplay?docId=sd00008014en_us&page=GUID-709AAADB-A9C1-40B6-AD22-958EE7E6F312.html>
- API e CLI: <https://support.hpe.com/hpesc/public/docDisplay?docId=sd00008014en_us&page=GUID-F695DE83-0DF8-4C5E-A932-79B60E12C7B4.html>
- Repositórios no GitHub: <https://github.com/HewlettPackard/?q=morpheus&type=all&language=&sort=>
- Whitepapers: <https://www.hpe.com/us/en/resource-library.html/search/morpheus?type=whitepapers-and-reports>

## Segurança e estado

- Nunca armazenar credenciais hardcoded em `.tf`.
- Não versionar estado local ou artefatos sensíveis.

## Fluxo de validação (antes de propor merge)

- `terraform fmt`
- `terraform validate`
- `terraform plan` revisado
