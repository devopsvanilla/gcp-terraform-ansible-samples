---
mode: "agent"
description: "Cria uma POC mínima em Terraform para GCP com README padronizado e scripts Bash auxiliares"
---

Crie uma nova POC em `PoCs/<nome-da-poc>/` para Terraform na GCP, com foco em unidade mínima de implantação e validação objetiva.

## Requisitos obrigatórios

1. Criar diretório próprio da POC.
2. Criar Terraform com boas práticas (estrutura clara, variáveis e outputs documentados).
3. Criar `README.md` da POC com as seções obrigatórias:
   - O que será implantado
   - Pré-requisitos
   - Como implantar
   - Como conferir a implantação
   - Como descomissionar
   - Guia de erros comuns
4. Se criar scripts, usar Bash Linux com `set -euo pipefail`, `--help` e validação de dependências.
5. Atualizar o `README.md` da raiz com índice da nova POC.

## Qualidade esperada

- POC de baixo custo e fácil remoção.
- Passos reproduzíveis para analista júnior.
- Comandos de verificação concretos (CLI e/ou Console).
- Nenhum segredo hardcoded.

## Referências (não copiar conteúdo; aplicar como guideline)

- Terraform style: https://developer.hashicorp.com/terraform/language/style
- Terraform tests: https://developer.hashicorp.com/terraform/language/tests
- Terraform na GCP: https://docs.cloud.google.com/docs/terraform
- Best practices GCP (general): https://docs.cloud.google.com/docs/terraform/best-practices/general-style-structure
- Bash style: https://google.github.io/styleguide/shellguide.html
- ShellCheck: https://www.shellcheck.net/
