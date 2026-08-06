---
applyTo: "**/*.tf"
description: "Padrões para manifestos Terraform utilizando o provedor HPE Morpheus Data (HPE/hpe)"
---

# Terraform (HPE Morpheus Data) — Regras do repositório

Use estas regras para manifestos Terraform que utilizam o provedor HPE para Morpheus Data neste repositório.

## Resultado esperado

- Implementar automações para Morpheus Data (Tasks, Workflows, Instâncias, Blueprint, Repositórios, etc.).
- Manter código parametrizado, seguro, previsível e fácil de destruir/limpar.

## Provedor Terraform Oficial

- Provedor: `HPE/hpe` (Registry: `https://registry.terraform.io/providers/HPE/hpe/latest`)
- Configuração de bloco provider (`versions.tf`):
  ```hcl
  terraform {
    required_providers {
      hpe = {
        source  = "HPE/hpe"
        version = "~> 0.1" # Ajustar para a versão utilizada
      }
    }
  }
  ```

## Convenções de Parâmetros e Credenciais

- Parâmetros obrigatórios de conexão (ex.: `url`, `access_token` ou `app_token`) devem ser definidos em variáveis (`variables.tf`).
- **Nunca commit segredos ou tokens**. Utilize `sensitive = true` em variáveis de credenciais.
- Forneça um `terraform.tfvars.example` com valores mascarados.

## Documentação Oficial de Referência (Morpheus Data / HPE)

Quando precisar de detalhes de configuração, API, CLI ou console web do Morpheus Data, consulte exclusivamente as fontes oficiais:

- **Provedor Terraform HPE**: <https://registry.terraform.io/providers/HPE/hpe/latest>
- **Console Web & Configurações da Solução**: <https://support.hpe.com/hpesc/public/docDisplay?docId=sd00008014en_us&page=GUID-709AAADB-A9C1-40B6-AD22-958EE7E6F312.html>
- **API e CLI Morpheus Data**: <https://support.hpe.com/hpesc/public/docDisplay?docId=sd00008014en_us&page=GUID-F695DE83-0DF8-4C5E-A932-79B60E12C7B4.html>
- **Repositórios no GitHub (HPE)**: <https://github.com/HewlettPackard/?q=morpheus&type=all&language=&sort=>
- **Whitepapers e Relatórios**: <https://www.hpe.com/us/en/resource-library.html/search/morpheus?type=whitepapers-and-reports>

## Fluxo de Validação

- `terraform fmt`
- `terraform validate`
- `terraform plan`
