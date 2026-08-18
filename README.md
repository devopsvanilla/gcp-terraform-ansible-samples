# gcp-terraform-ansible-samples

Repositório de provas de conceito (PoCs) para Google Cloud Platform com foco em Terraform e automações auxiliares, priorizando baixo custo, simplicidade e validação objetiva.

## Como o repositório está organizado

- `PoCs/<nome-da-poc>/`: cada PoC fica isolada em um diretório próprio.
- `scripts/`: utilitários e automações de apoio (setup do projeto GCP, codificação de credenciais, etc.).
- `.github/instructions/`: padrões de qualidade e convenções do repositório.

## Índice das PoCs

| PoC | Descrição |
|---|---|
| [`PoCs/gcp-create-vm`](PoCs/gcp-create-vm/README.md) | Terraform puro para provisionamento de VM Compute Engine no GCP (sem Ansible, sem Nginx). |
| [`PoCs/morpheus-tf-nativestate`](PoCs/morpheus-tf-nativestate/README.md) | App Blueprint Terraform Nativo no Morpheus Data com estado (`tfstate`) no Cypher e formulário de Self-Service. Aponta para `PoCs/gcp-create-vm`. |
| [`PoCs/morpheus-tf-remotestate`](PoCs/morpheus-tf-remotestate/README.md) | Integração Morpheus Data via Remote Backend (GCS) com script wrapper Shell Task. |
| [`PoCs/vm-nginx-terraform-ansible`](PoCs/vm-nginx-terraform-ansible/README.md) | PoC original com Terraform + Ansible para instalação automatizada do Nginx. |

## Pré-requisitos gerais

### Ferramentas no host de execução

| Ferramenta | Versão mínima | Uso |
|---|---|---|
| `terraform` | >= 1.6.0 | Provisionar infraestrutura e configurar o Morpheus Data |
| `gcloud` CLI | Última estável | Configuração do projeto GCP, APIs, Org Policies e IAM |
| `git` | Qualquer | Versionamento e push para o repositório remoto |

> **Nota:** O runner nativo do Morpheus Data **não possui** `gcloud` nem `ansible-playbook` instalados. Todo código executado dentro do Blueprint deve ser autossuficiente (APIs GCP nativas do provider Terraform, `metadata_startup_script`, etc.).

### Autenticação no GCP

- Configure a autenticação antes de aplicar infraestrutura. Consulte o guia [`HOWTO-gcloud-connect.md`](PoCs/morpheus-tf-nativestate/HOWTO-gcloud-connect.md).
- Use o script [`scripts/setup-gcp-project.sh`](scripts/setup-gcp-project.sh) para habilitar APIs, configurar Org Policies e preparar o projeto GCP.

## Observações de segurança

- **Nunca versione** credenciais, chaves privadas ou arquivos de estado Terraform (`.tfstate`, `terraform.tfvars`).
- Sempre revise `terraform plan` antes de `terraform apply`.
- Descomissione recursos ao final dos testes (`terraform destroy`) para evitar custos desnecessários.
