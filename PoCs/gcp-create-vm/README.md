# PoC: Provisionamento de VM no Google Cloud Platform (GCP) com Terraform

Esta PoC contém a automação em **Terraform puro** para provisionamento declarativo de instâncias Compute Engine (GCE) no Google Cloud Platform (GCP).

É a PoC de execução utilizada pelo App Blueprint Nativo do Morpheus Data em [`PoCs/morpheus-tf-nativestate`](../morpheus-tf-nativestate/README.md).

## Recursos Criados

1. **Compute Engine VM**:
   - Instância customizável (série, tipo de máquina, vCPU, RAM).
   - Disco de boot Persistent Disk (tamanho e imagem de SO configuráveis).
   - Atribuição opcional de IP público externo.
   - Injeção nativa de chaves públicas SSH via metadados e `metadata_startup_script`.
   - Criação automática de usuário Linux, grupos adicionais e permissões `sudo`.

2. **Firewall VPC**:
   - Liberação de portas HTTP (80) e SSH (22) com CIDRs configuráveis.

## Pré-requisitos

| Ferramenta | Versão | Uso |
|---|---|---|
| **Terraform CLI** | >= 1.6.0 | Provisionamento da infraestrutura |
| **gcloud CLI** | Última estável | Configuração prévia do projeto GCP (APIs, IAM, Org Policy) |

### Permissões GCP da Service Account

| Role IAM | Finalidade |
|---|---|
| `roles/compute.admin` | Criar/gerenciar VMs, discos e regras de firewall |
| `roles/iam.serviceAccountUser` | Associar Service Accounts às instâncias |

### Org Policy `compute.vmExternalIpAccess`

Se o projeto GCP tiver a restrição `constraints/compute.vmExternalIpAccess` ativa, a criação de VMs com IP externo falhará com erro `412 conditionNotMet`. Resolva previamente:

```bash
./scripts/setup-gcp-project.sh --project-id SEU_PROJECT_ID
```

## Como Executar Localmente

```bash
cd PoCs/gcp-create-vm
cp terraform.tfvars-SAMPLE terraform.tfvars
# Edite o terraform.tfvars com as configurações do seu projeto GCP
terraform init
terraform plan
terraform apply
```

## Como Executar via Morpheus Data

Esta PoC é executada automaticamente quando um usuário solicita o App Blueprint no Catálogo do Morpheus Data. A configuração do Blueprint e item de catálogo é feita pela PoC [`PoCs/morpheus-tf-nativestate`](../morpheus-tf-nativestate/README.md).

## Importante

> ⚠️ **Este código é executado dentro do runner nativo do Morpheus Data**, que **não possui** `gcloud`, `ansible-playbook` nem outras ferramentas CLI. Todo o provisionamento é feito exclusivamente via:
> - Provider Terraform `hashicorp/google` (APIs nativas do GCP).
> - `metadata_startup_script` para configuração pós-boot da VM.
> - `metadata.ssh-keys` para injeção de chaves SSH.
>
> **Nunca adicione provisioners `local-exec` que dependam de ferramentas CLI neste código.**

## Referências

- 📖 **Configuração do Blueprint no Morpheus**: [`PoCs/morpheus-tf-nativestate/README.md`](../morpheus-tf-nativestate/README.md)
- 🔐 **Conectividade GCP e GitHub**: [`PoCs/morpheus-tf-nativestate/HOWTO-gcloud-connect.md`](../morpheus-tf-nativestate/HOWTO-gcloud-connect.md)
- ☁️ **Terraform GCP Provider**: [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
