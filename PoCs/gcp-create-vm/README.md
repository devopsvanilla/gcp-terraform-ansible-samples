# PoC: Provisionamento de VM no Google Cloud Platform (GCP) com Terraform

Esta PoC contém a automação em **Terraform puro** para provisionamento declarativo de instâncias Compute Engine (GCE) no Google Cloud Platform (GCP).

## Recursos Criados

1. **Compute Engine VM**:
   - Instância customizável (série, tipo de máquina, vCPU, RAM).
   - Disco de boot Persistent Disk (tamanho e imagem de SO configuráveis).
   - Atribuição opcional de IP público externo.
   - Injeção nativa de chaves públicas SSH via metadados e script de inicialização (`metadata_startup_script`).
2. **Firewall VPC**:
   - Liberação de portas HTTP (80) e SSH (22) com CIDRs configuráveis.

## Como Executar Localmente

```bash
cd PoCs/gcp-create-vm
cp terraform.tfvars-SAMPLE terraform.tfvars
# Edite o terraform.tfvars com as configurações do seu projeto GCP
terraform init
terraform plan
terraform apply
```
