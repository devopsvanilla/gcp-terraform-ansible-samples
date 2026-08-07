# Como Recuperar o `tfstate` do Morpheus Cypher e Corrigir Drifts Locais

Este guia detalha o procedimento passo a passo para extrair o arquivo de estado do Terraform (`terraform.tfstate`) mantido pelo runner nativo do Morpheus Data (armazenado no cofre criptografado **Morpheus Cypher**), executá-lo na sua máquina local para detecção e correção de *drifts* (desvios de infraestrutura no GCP) e ressincronizar o estado atualizado de volta no Morpheus Data.

---

## 1. Visão Geral da Arquitetura do Native State

No App Blueprint Nativo ([`hpe_morpheus_app_blueprint_terraform`](./README.md)), o runner do Morpheus Data gerencia o estado da aplicação sem depender de um bucket remoto como GCS ou S3. O estado `.tfstate` fica armazenado e criptografado no **Cypher** (ou no banco de dados da App Instance).

Embora conveniente para automações centralizadas no Morpheus, a edição local ou a investigação de desalinhamentos na infraestrutura (recursos alterados manualmente no GCP via Console ou `gcloud` CLI) exige a recuperação temporária desse estado para o seu terminal local.

---

## 2. Passo a Passo de Recuperação e Correção de Drift

### Passo 1: Extrair o `tfstate` e as `tfvars` do Morpheus

Você precisa obter dois arquivos do Morpheus para reproduzir a execução localmente:
1. **`terraform.tfstate`**: O estado atual dos recursos registrados pela App Instance.
2. **`terraform.tfvars`**: Os parâmetros de configuração injetados pelo segredo do Cypher.

#### Método A: Via Console Web (Interface Gráfica)
1. Acesse **Provisioning > Apps** e selecione a App Instance da aplicação (ex.: `vm-nginx-poc`).
2. Acesse a aba **State** (ou consulte no histórico de logs da execução) e exporte/copie o JSON do `terraform.tfstate`.
3. Navegue até **Tools > Cypher**, abra a chave do segredo de `tfvars` configurada (ex.: `tfvars/vm-nginx-poc`) e copie o seu conteúdo.

#### Método B: Via CLI do Morpheus ou API REST (Automatizado)
Você pode utilizar a CLI do Morpheus ou requisições `curl` para baixar o estado e as variáveis diretamente no terminal:

```bash
# Definir variáveis de ambiente para a API
MORPHEUS_URL="https://morpheus.seu-dominio.com"
MORPHEUS_TOKEN="seu-access-token"
APP_INSTANCE_KEY="secret/tfstate/vm-nginx-poc" # ou a chave específica da App Instance
TFVARS_KEY="tfvars/vm-nginx-poc"

# Baixar o tfstate via Curl
curl -k -s -H "Authorization: Bearer $MORPHEUS_TOKEN" \
  "$MORPHEUS_URL/api/cypher/$APP_INSTANCE_KEY" \
  | jq -r '.cypher.itemData' > terraform.tfstate

# Baixar o tfvars via Curl
curl -k -s -H "Authorization: Bearer $MORPHEUS_TOKEN" \
  "$MORPHEUS_URL/api/cypher/$TFVARS_KEY" \
  | jq -r '.cypher.itemData' > terraform.tfvars
```

---

### Passo 2: Preparar o Ambiente Local

1. Navegue até o diretório do manifesto Terraform ([`PoCs/vm-nginx-terraform-ansible`](../vm-nginx-terraform-ansible/README.md)):
   ```bash
   cd PoCs/vm-nginx-terraform-ansible
   ```

2. Mova ou salve os arquivos `terraform.tfstate` e `terraform.tfvars` recuperados no **Passo 1** para dentro desta pasta (`PoCs/vm-nginx-terraform-ansible`).

3. Garanta que o terminal esteja autenticado no projeto GCP correto com o Application Default Credentials (`ADC`):
   ```bash
   gcloud auth application-default login
   ```

4. Inicialize os provedores do Terraform na pasta local:
   ```bash
   terraform init
   ```
   *Nota: Como o manifesto não possui bloco `backend`, o Terraform utilizará automaticamente o arquivo `terraform.tfstate` local que você baixou.*

---

### Passo 3: Executar o Drift Detection (`terraform plan`)

Para identificar se houve qualquer alteração na infraestrutura real (GCP) em comparação com o código e o estado registrado:

```bash
terraform plan
```

O Terraform lerá o estado das VMs, discos e regras de firewall diretamente da API do GCP e exibirá o relatório detalhado de desvios (*drift*):
- **Recursos modificados externamente**: Serão exibidos com `~` (update em tempo de execução).
- **Recursos excluídos manualmente**: Serão exibidos com `+` (necessidade de recriação).

---

### Passo 4: Aplicar Correções de Drift

Conforme a estratégia da sua equipe, escolha como tratar o *drift*:

#### Opção A: Forçar a Infraestrutura a Voltar ao Código (Reconciliar GCP com o Terraform)
Para reverter quaisquer alterações manuais feitas no GCP e restaurar a infraestrutura exatamente como definida no manifesto:
```bash
terraform apply
```

#### Opção B: Atualizar o Estado mantendo a alteração do GCP (*Refresh Only*)
Caso a alteração feita no GCP tenha sido intencional e você deseje apenas sincronizar o `tfstate` sem alterar nada no cloud provider:
```bash
terraform apply -refresh-only
```

---

### Passo 5: Ressincronizar o State Atualizado com o Morpheus Cypher

Após executar o `terraform apply` ou `terraform apply -refresh-only` localmente, o seu arquivo `terraform.tfstate` terá uma nova versão (campo `serial` incrementado). É **fundamental** enviar esse novo estado de volta ao Morpheus Cypher para evitar conflitos na próxima execução do runner.

#### Atualizar no Cypher via CLI ou API REST:
```bash
# Via Morpheus CLI:
morpheus cypher put "$APP_INSTANCE_KEY" -f terraform.tfstate

# Via API REST Curl:
curl -k -X POST -H "Authorization: Bearer $MORPHEUS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"value\": $(jq -Rs . terraform.tfstate)}" \
  "$MORPHEUS_URL/api/cypher/$APP_INSTANCE_KEY"
```

---

## 3. Comparativo: Native State (Cypher) vs Remote State (GCS)

Se a sua equipe precisa realizar correções de *drift* e execuções locais frequentes fora da console do Morpheus Data, avalie utilizar o padrão de **Remote Backend (GCS)** demonstrado na PoC [`PoCs/morpheus-tf-remotestate`](../morpheus-tf-remotestate/README.md).

| Funcionalidade | Native State (Morpheus Cypher) | Remote State (GCS Bucket) |
| :--- | :--- | :--- |
| **Local do `tfstate`** | Interno do Morpheus Cypher | Bucket do Google Cloud Storage (`gcs`) |
| **Execução Local de `terraform plan`** | Requer extração manual via API/UI | Direta via `terraform init -reconfigure` |
| **Sincronização Pós-Drift** | Requer envio manual de volta ao Cypher | Automática no bucket GCS |
| **Complexidade de Setup** | Baixa (sem dependência de bucket GCP) | Média (exige criação prévia do bucket) |
| **PoC de Referência** | [`PoCs/morpheus-tf-nativestate`](./README.md) | [`PoCs/morpheus-tf-remotestate`](../morpheus-tf-remotestate/README.md) |

---

## 4. Referências

* [PoC Morpheus Native State README](./README.md)
* [PoC Morpheus Remote State README](../morpheus-tf-remotestate/README.md)
* [Guia de Utilização do Módulo `tfvars` no Cypher](../morpheus-tf-remotestate/HOWTO-cypher-tfvars.md)
* [Documentação do Morpheus Data - Cypher Management](https://docs.morpheusdata.com/en/latest/tools/cypher/cypher.html)
