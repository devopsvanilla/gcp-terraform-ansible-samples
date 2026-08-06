---
name: poc-readme-validator
description: Valida a conformidade e ordem das 6 seções obrigatórias no README.md das PoCs deste repositório.
---

# Skill: POC README Validator

Esta skill garante que a documentação de cada POC siga rigorosamente a estrutura exigida pelo repositório.

---

## Quando Utilizar esta Skill

- Ao criar ou atualizar o `README.md` de qualquer POC em `PoCs/<nome-da-poc>/`.
- Durante a fase de validação de PRs ou Quality Gates de documentação.

---

## Regras de Estrutura do README de POC

O arquivo `PoCs/<nome-da-poc>/README.md` **deve obrigatoriamente** conter exatamente as 6 seções abaixo, na seguinte ordem exata (títulos H2 ou H3):

1. **O que será implantado**
   - Descrição sucinta da arquitetura e recursos GCP criados (Compute Engine, VPC, Storage, etc.).
   - Indicação explicita de custos/limitações esperados.

2. **Pré-requisitos**
   - Ferramentas necessárias (`gcloud`, `terraform`, `ansible`, `bash`).
   - Permissões mínimas GCP / Roles necessárias no projeto.
   - APIs do Google Cloud que precisam estar habilitadas.

3. **Como implantar**
   - Comandos passo a passo para autenticação, inicialização e aplicação do Terraform (`gcloud auth`, `terraform init`, `terraform apply`).
   - Passos para execução do Ansible caso aplicável.

4. **Como conferir a implantação**
   - Comandos de validação concretos via CLI (`gcloud compute instances list`, `curl`, `ping`, etc.) e/ou verificação via Console Web GCP.

5. **Como descomissionar**
   - Instruções exatas e seguras para destruição dos recursos (`terraform destroy`) evitando custos residuais no GCP.

6. **Guia de erros comuns**
   - Problemas conhecidos (ex: API desabilitada, cota excedida, erro de permissão IAM, SSH falhando) e como resolvê-los.

---

## Regras de Redação

- Linguagem direta e reproduzível para analistas de nível júnior.
- Comandos formatados em blocos de código markdown (`bash ...`).
- Proibido omitir qualquer uma das 6 seções.
