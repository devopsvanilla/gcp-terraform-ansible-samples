# Como Autenticar o Morpheus Data e o Terraform no Google Cloud Platform (GCP)

Este guia descreve os passos necessários para autenticar o **Morpheus Data** e os manifestos **Terraform** executados por ele na sua conta e projeto do Google Cloud Platform (GCP).

---

## 1. Visão Geral dos Métodos de Autenticação

A forma como o Morpheus se conecta ao GCP depende do modelo de execução adotado:

| Método | Indicado Para | Como Funciona | Armazenamento da Credencial |
| :--- | :--- | :--- | :--- |
| **Método 1: Service Account Key via Cypher** | Tasks de Shell / Operational Workflows (Padrão deste repositório) | Injeção da variável `GOOGLE_CREDENTIALS` contendo a chave JSON lida do Cypher | Secret Store no Morpheus (**Tools > Cypher**) |
| **Método 2: Cloud Integration Nativa** | App Blueprints Nativos de Terraform | Cadastro do GCP como Cloud Provider no Morpheus Data | Cadastro de Cloud no Morpheus (**Infrastructure > Clouds**) |
| **Método 3: Application Default Credentials (ADC)** | Morpheus / Runner hospedado no próprio GCP (GCE ou GKE) | Autenticação via Metadata Server da GCP / Workload Identity | IAM da VM / Service Account nativa da GCP |

---

## 2. Método 1: Service Account Key via Cypher (Recomendado para Tasks e Workflows)

Este é o método padrão utilizado pelas automações deste repositório (como o script [`add_vm_and_apply.sh`](PoCs/morpheus/templates/add_vm_and_apply.sh)).

### Passo 1: Criar a Service Account no GCP

No terminal com o `gcloud` configurado, crie uma Service Account dedicada para a automação:

```bash
gcloud iam service-accounts create morpheus-tf-runner \
  --description="Service Account para o Morpheus Data executar o Terraform" \
  --display-name="morpheus-tf-runner"
```

### Passo 2: Conceder Permissões no Projeto GCP

Atribua as permissões necessárias no projeto GCP onde a infraestrutura será criada (substitua `SEU_PROJECT_ID` pelo ID do seu projeto):

```bash
# Permissão para gerenciar instâncias Compute Engine e redes
gcloud projects add-iam-policy-binding SEU_PROJECT_ID \
  --member="serviceAccount:morpheus-tf-runner@SEU_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# Permissão para gerenciar o estado do Terraform no Cloud Storage (GCS)
gcloud projects add-iam-policy-binding SEU_PROJECT_ID \
  --member="serviceAccount:morpheus-tf-runner@SEU_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/storage.admin"

# Permissão para alterar Service Accounts/usuários (caso aplicável)
gcloud projects add-iam-policy-binding SEU_PROJECT_ID \
  --member="serviceAccount:morpheus-tf-runner@SEU_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

### Passo 3: Gerar a Chave JSON da Service Account

Crie o arquivo de chave privada em formato JSON:

```bash
gcloud iam service-accounts keys create gcp-key.json \
  --iam-account=morpheus-tf-runner@SEU_PROJECT_ID.iam.gserviceaccount.com
```

> ⚠️ **ATENÇÃO:** Nunca versione o arquivo `gcp-key.json` no Git. Ele contém acesso administrativo ao seu projeto GCP.
>
> 💡 **Nota:** Se a execução deste comando falhar com o erro `FAILED_PRECONDITION: Key creation is not allowed on this service account`, o seu projeto possui uma política de organização bloqueando a criação de chaves. Veja como resolver na seção [Resolução de Problemas Comuns](#5-resolução-de-problemas-comuns).

### Passo 4: Armazenar a Chave no Cypher do Morpheus Data

1. Na interface web do Morpheus Data, acesse **Ferramentas (Tools) > Cypher**.
2. Clique no botão **+ Adicionar (+ Add)**.
3. Preencha os dados:
   * **Chave (Key)**: `secret/gcp-credentials`
   * **Tipo (Type)**: `Secret`
   * **Valor (Value)**: Abra o arquivo `gcp-key.json`, copie todo o conteúdo JSON e cole neste campo.
   * **TTL**: `0` (ilimitado).
4. Clique em **Salvar (Save)**.

### Passo 5: Injetar a Credencial no Script da Task do Morpheus

O provider `google` do Terraform reconhece automaticamente a variável de ambiente `GOOGLE_CREDENTIALS` quando ela contém a string JSON da Service Account.

No script da Task (ou em [`templates/add_vm_and_apply.sh`](PoCs/morpheus/templates/add_vm_and_apply.sh)), adicione antes de executar os comandos do Terraform:

```bash
# Injeta o conteúdo do segredo lido dinamicamente do Cypher
export GOOGLE_CREDENTIALS='<%=cypher.read("secret/gcp-credentials")%>'
```

Ao executar `terraform init` e `terraform apply`, o provider utilizará automaticamente essa credencial.

---

## 3. Método 2: Integração Nativa da GCP no Morpheus (Cloud Integration)

Se você estiver utilizando **App Blueprints Nativos do tipo Terraform** no Morpheus Data:

1. Acesse **Infraestrutura (Infrastructure) > Clouds**.
2. Clique em **+ Adicionar (+ Add)** e selecione **Google Cloud Platform (GCP)**.
3. Preencha os campos obrigatórios:
   * **Nome (Name)**: Ex: `GCP Production` ou `GCP Staging`.
   * **Project ID**: O ID do projeto GCP.
   * **Service Account Key**: Cole o conteúdo completo do arquivo `gcp-key.json`.
4. Clique em **Salvar (Save)**.

O Morpheus autenticará na GCP, descobrirá regiões, VPCs e imagens, e repassará essas credenciais automaticamente para as execuções de Blueprints vinculados a essa Cloud.

---

## 4. Método 3: Workload Identity / Credentials do Host (Runner no GCP)

Caso o Morpheus Data (ou o Runner da Task) esteja rodando em uma máquina virtual (Compute Engine) ou cluster GKE dentro da GCP:

1. **Vínculo de Service Account à VM**:
   Ao criar a VM do Runner, associe a Service Account `morpheus-tf-runner` diretamente na criação da instância.
2. **Workload Identity (GKE)**:
   Mapeie a Kubernetes Service Account (KSA) do Pod do Runner para a Google Service Account (GSA).
3. **Execução Transparente**:
   Neste cenário, não é necessário gerar arquivos de chave JSON ou injetar tokens. O `gcloud` e o Terraform obtêm as credenciais dinamicamente via **Metadata Server** (`http://metadata.google.internal`).

---

## 5. Resolução de Problemas Comuns

- **Erro `FAILED_PRECONDITION: Key creation is not allowed on this service account` (`constraints/iam.disableServiceAccountKeyCreation`)**:
  - Esse erro é provocado por uma política de organização (Organization Policy) do GCP que proíbe a criação de chaves privadas JSON.
  - Para liberar a criação de chaves no projeto utilizando a API Org Policies v2:
    ```bash
    cat <<EOF > override_key_policy.yaml
    name: projects/SEU_PROJECT_ID/policies/iam.disableServiceAccountKeyCreation
    spec:
      rules:
      - enforce: false
    EOF

    gcloud org-policies set-policy override_key_policy.yaml
    rm -f override_key_policy.yaml
    ```
  - Confirme se a regra foi desativada (`enforce: false`):
    ```bash
    gcloud org-policies describe iam.disableServiceAccountKeyCreation --project=SEU_PROJECT_ID
    ```
  - **Aguarde cerca de 60 segundos** para a propagação da política nos servidores do IAM do GCP e tente executar novamente a criação da chave (`gcloud iam service-accounts keys create ...`).

- **Erro `401 Unauthorized` ou `403 Forbidden`**:
  - Verifique se as APIs do GCP necessárias (como `compute.googleapis.com`, `storage.googleapis.com`) estão ativadas no projeto (`gcloud services enable compute.googleapis.com storage.googleapis.com`).
  - Confirme se a Service Account possui as roles necessárias no projeto.
- **Erro `storage.buckets.get permission denied`**:
  - Garanta que a Service Account possui a role `roles/storage.admin` ou `roles/storage.objectAdmin` no bucket de backend do Terraform.
- **Formato JSON inválido no Cypher**:
  - Certifique-se de que colou o JSON bruto da chave sem quebras de linha extras ou aspas adicionais.

---

## 6. Referências

- [Documentação Oficial do Morpheus Data - Cypher](https://docs.morpheusdata.com/en/latest/tools/cypher/cypher.html)
- [Documentação do Provider Google do Terraform - Autenticação](https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference#authentication)
- [Guia do Módulo `tfvars` no Cypher](PoCs/morpheus/HOWTO-cypher-tfvars.md)
