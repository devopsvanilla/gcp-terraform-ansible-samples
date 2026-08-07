# gcp-terraform-ansible-samples

Repositório de provas de conceito (POCs) para Google Cloud Platform com foco em Terraform e automações auxiliares (principalmente Bash Linux e Ansible), priorizando baixo custo, simplicidade e validação objetiva.

## Como o repositório está organizado

- `PoCs/<nome-da-poc>/`: cada POC fica isolada em um diretório próprio.
- `scripts/`: utilitários e automações de apoio.
- `.github/instructions/`: padrões de qualidade e convenções do repositório.

## Índice das POCs existentes

- [PoCs/vm-nginx-terraform-ansible](PoCs/vm-nginx-terraform-ansible/README.md): Integração Morpheus Data via Remote Backend (GCS) executando script wrapper Shell Task e workflow de self-service.
- [PoCs/morpheus-tf-remotestate](PoCs/morpheus-tf-remotestate/README.md): Integração Morpheus Data via Remote Backend (GCS) executando script wrapper Shell Task e workflow de self-service.
- [PoCs/morpheus-tf-nativestate](PoCs/morpheus-tf-nativestate/README.md): App Blueprint Terraform Nativo no Morpheus Data com estado (`tfstate`) mantido no Cypher e formulário de Self-Service com Option Types individuais.

## Observações gerais de pré-requisitos e segurança

- Tenha `terraform`, `gcloud` e `ansible` instalados e atualizados.
- Configure a autenticação no GCP antes de aplicar infraestrutura. Consulte o guia [HOWTO-gcloud-connect.md](HOWTO-gcloud-connect.md) para aprender a autenticar o Morpheus Data e o Terraform na sua conta e projeto GCP.
- A PoC de VM Nginx já inclui criação automática de usuário remoto na VM, grupos configuráveis por VM e execução automática do playbook do Ansible pelo Terraform quando `run_ansible = true`.
- Nunca versione credenciais, chaves privadas ou arquivos de estado Terraform.
- Sempre revise `terraform plan` antes de `terraform apply`.
- Descomissione recursos ao final dos testes (`terraform destroy`) para evitar custos desnecessários.
