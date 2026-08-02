---
applyTo: "**/README.md"
description: "Estrutura de documentação para README raiz e README de POCs"
---

# Regras para READMEs

## README da raiz (`/README.md`)

Deve conter:

1. Propósito do repositório
2. Como o repositório está organizado
3. Índice das POCs existentes (link por diretório)
4. Observações gerais de pré-requisitos e segurança

## README de cada POC (`PoCs/<nome>/README.md`)

Deve conter **exatamente** as seções abaixo (nesta ordem):

1. O que será implantado
2. Pré-requisitos
3. Como implantar
4. Como conferir a implantação
5. Como descomissionar
6. Guia de erros comuns

## Regras de redação

- Passo a passo objetivo para analista júnior.
- Comandos de execução e validação claros.
- Indicar custos/limitações quando relevante.
- Incluir critérios de sucesso mensuráveis para a POC.

## Evitar

- Tópicos sem ação prática.
- Ambiguidade sobre destruição de recursos.
- Dependência de conhecimento implícito não documentado.
