# Guia de Configuração e Conexão GCP / GitHub / Cypher — Morpheus Native Backend PoC

Este documento detalha todos os pré-requisitos, permissões do Google Cloud Platform (GCP), integração com GitHub, segredos no Morpheus Cypher e o preenchimento do arquivo [`terraform.tfvars`](./terraform.tfvars-SAMPLE) para a execução do **App Blueprint Nativo com Backend de Estado no Cypher** (`morpheus-tf-nativestate`).

> 📘 **Nota Central:** Este guia é específico sobre integrações e permissões. O documento principal sobre o funcionamento da automação, os recursos provisionados e o passo a passo de implantação via Terraform é o [`README.md`](./README.md).

---

## 1. Visão Geral da Integração

Nesta arquitetura **Native State**, o Morpheus Data atua diretamente como o orquestrador do ciclo de vida do Terraform (`init`, `plan`, `apply`, `destroy`), utilizando o código-fonte hospedado no repositório **GitHub** e armazenando o arquivo de estado (`.tfstate`) de forma segura e criptografada no **Morpheus Cypher**.

Para que essa automação funcione sem intervenções manuais, a infraestrutura exige três pilares de preparação:

1. **GCP Project & IAM**: Conta de serviço (Service Account) com roles adequadas para criar instâncias Compute Engine e regras de firewall VPC.
2. **GitHub SCM Integration**: Repositório vinculado no Morpheus Data para download automático do código Terraform.
3. **Morpheus Cypher**: Segredo configurado para injeção automática de variáveis (`tfvars/<cypher_secret_key>`).

### Limitações do Runner Nativo do Morpheus

> ⚠️ **Importante:** O runner nativo do Morpheus Data executa o Terraform dentro de um container que **não possui** `gcloud`, `ansible-playbook` nem outras ferramentas CLI no PATH. Consequências:
>
> - **Nunca use provisioners `local-exec`** que dependam de CLI externas no código do Blueprint.
> - Use `metadata_startup_script` para configuração pós-boot da VM.
> - Use o provider Terraform nativo do Google (`hashicorp/google`) para todas as operações de API.
> - Use `metadata.ssh-keys` para injeção de chaves SSH.

---

## 2. Permissões e Recursos a Criar Antecipadamente no GCP

### Passo 1: Executar o script de setup do projeto (Recomendado)

O script [`scripts/setup-gcp-project.sh`](../../scripts/setup-gcp-project.sh) automatiza todos os passos abaixo. Execute com uma conta administrativa:

```bash
./scripts/setup-gcp-project.sh --project-id SEU_PROJECT_ID
```

O script:
- Habilita as APIs necessárias (Compute Engine, Org Policy, Service Usage, IAM, Cloud Resource Manager).
- Define o quota project para a conta ADC atual.
- Configura a Org Policy `compute.vmExternalIpAccess` com `allowAll: true` para permitir IP externo nas VMs.

### Passo 2: Habilitar as APIs Necessárias (Manual)

Se preferir executar manualmente:

```bash
gcloud services enable \
  compute.googleapis.com \
  orgpolicy.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  serviceusage.googleapis.com \
  --project=SEU_PROJECT_ID
```

### Passo 3: Criar a Service Account da Automação

```bash
gcloud iam service-accounts create morpheus-tf-runner \
  --display-name="Morpheus Native Terraform Runner SA" \
  --project=SEU_PROJECT_ID
```

### Passo 4: Atribuir Roles IAM Necessárias

```bash
# Permissão para gerenciar instâncias Compute Engine, discos e regras de firewall VPC
gcloud projects add-iam-policy-binding SEU_PROJECT_ID \
  --member="serviceAccount:morpheus-tf-runner@SEU_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# Permissão para associar Service Accounts às instâncias criadas
gcloud projects add-iam-policy-binding SEU_PROJECT_ID \
  --member="serviceAccount:morpheus-tf-runner@SEU_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

> ⚠️ **Nota sobre `orgpolicy.policyAdmin`:** Esta role **não é suportada em nível de projeto** (`INVALID_ARGUMENT: Role roles/orgpolicy.policyAdmin is not supported for this resource`). Para gerenciar Org Policies, use o script `setup-gcp-project.sh` com uma conta que tenha permissão organizacional. O código em `PoCs/gcp-create-vm` **não manipula Org Policies**.

### Passo 5: Gerar a Chave Privada JSON da Service Account

```bash
gcloud iam service-accounts keys create gcp-key.json \
  --iam-account=morpheus-tf-runner@SEU_PROJECT_ID.iam.gserviceaccount.com
```

> ⚠️ **ATENÇÃO:** O arquivo `gcp-key.json` contém credenciais administrativas do GCP. **Nunca versione este arquivo no Git.**
>
> 💡 **Nota de Org Policy:** Se o comando acima falhar com `FAILED_PRECONDITION: Key creation is not allowed on this service account`, o GCP possui uma política de organização bloqueando a criação de chaves (`constraints/iam.disableServiceAccountKeyCreation`). Veja como resolver na seção de [Troubleshooting](#7-guia-de-resolução-de-problemas-comuns-troubleshooting).

---

## 3. Formas de Conectar as Credenciais GCP no Morpheus Data

O Morpheus Data pode autenticar no GCP de três maneiras distintas:

### Método 1: Integração Cloud Nativa GCP no Morpheus (Recomendado)

1. Na console web do Morpheus Data, acesse **Infrastructure > Clouds**.
2. Clique em **+ Add** e selecione **Google Cloud Platform**.
3. Em **Credentials**, selecione `Local Credentials` ou `New Credentials`:
   - **Client Email**: E-mail da Service Account (`morpheus-tf-runner@SEU_PROJECT_ID.iam.gserviceaccount.com`).
   - **Private Key**: Chave privada com quebras de linha (`-----BEGIN PRIVATE KEY-----\n...`).
4. Para extrair esses valores com a formatação correta a partir do `gcp-key.json`, utilize o script auxiliar:
   ```bash
   ./scripts/extract-gcp-credentials.sh
   ```
5. Selecione o **Project ID** (`SEU_PROJECT_ID`) e a **Region** (`us-central1`).
6. Clique em **Save**.

### Método 2: Armazenamento da Chave no Cypher

Para permitir que o App Blueprint Nativo autentique com segurança:

1. **Gerar a chave em formato Base64**:
   ```bash
   ./scripts/encode-gcp-key.sh
   ```
2. **Cadastrar no Cypher**:
   - Acesse **Tools > Cypher > + Add**.
   - **Key**: `secret/gcp-terraform-ansible-samples`
   - **Type**: `Secret`
   - **Value**: Cole o hash Base64 de linha única gerado pelo script.
   - **TTL**: `0`.

### Método 3: Credentials do Host / ADC (Runner no GCP)

Se o Morpheus Appliance ou o Runner/Worker do Morpheus estiver hospedado em uma instância Compute Engine no GCP:
1. Vincule a Service Account `morpheus-tf-runner` diretamente à VM do Morpheus/Runner.
2. A autenticação ocorrerá automaticamente via Metadata Server (`http://metadata.google.internal`).

---

## 4. Conexão do Repositório GitHub no Morpheus Data

O Blueprint nativo exige que o repositório Git que contém os arquivos do Terraform esteja cadastrado e sincronizado no Morpheus Data.

### Passo 1: Configurar a Integração Git no Morpheus

1. Acesse **Administration > Integrations**.
2. Clique em **+ Add Integration** e selecione **GitHub** (ou Git).
3. Preencha o nome da integração (ex.: `GitHub DevOps`).
4. Em **Authentication**, forneça um Personal Access Token (PAT) do GitHub ou chave SSH com permissão de leitura nos repositórios.
5. Salve a integração.

### Passo 2: Adicionar e Sincronizar o Repositório

1. Dentro da integração criada em **Administration > Integrations**, acesse a aba **Repositories**.
2. Adicione o repositório contendo o projeto `gcp-terraform-ansible-samples`.
3. Clique em **Refresh / Sync** para que o Morpheus indexe as branches e diretórios do repositório.

### Passo 3: Obter os IDs Numéricos (`integration_id` e `repository_id`)

Os recursos `hpe_morpheus_app_blueprint_terraform` exigem os IDs numéricos internos do Morpheus Data:

- **`integration_id`**: Abra a integração em **Administration > Integrations** e observe o ID numérico na URL do navegador.
  - *Exemplo*: Na URL `https://morpheus.example.com/admin/integrations/15/code`, o ID é **`15`**.
- **`repository_id`**: Acesse **Provisioning > Code > Repositories** e observe o ID na URL ao abrir o repositório.
  - *Exemplo*: Na URL `https://morpheus.example.com/provisioning/code/repos/63`, o ID é **`63`**.

---

## 5. Estrutura e Configuração do Morpheus Cypher

Nesta PoC nativa, o Morpheus Cypher armazena o payload das variáveis Terraform:

```
Estrutura de Chaves Cypher:
└── tfvars/<cypher_secret_key>   <-- Armazena o payload das tfvars injetado no terraform plan/apply
```

- **`tfvars/<cypher_secret_key>`**:
  - Criado automaticamente pela automação Terraform ([`cypher.tf`](./cypher.tf)).
  - Guarda o bloco JSON com os valores dos parâmetros da VM e projeto GCP.
  - O Morpheus lê esse segredo durante o provisionamento através da propriedade `tfvar_secret` do Blueprint.

---

## 6. Detalhamento dos Parâmetros do `terraform.tfvars-SAMPLE`

O arquivo [`terraform.tfvars-SAMPLE`](./terraform.tfvars-SAMPLE) é o modelo para a configuração da automação. Abaixo está a explicação detalhada de cada seção:

### A. Conexão com o Morpheus Data

| Parâmetro | Descrição |
|---|---|
| `morpheus_url` | URL completa da console do Morpheus Data (ex.: `https://morpheus.seu-dominio.com`) |
| `morpheus_username` / `morpheus_password` | Credenciais de usuário/senha com privilégios administrativos. **Use `\\` duplo para domínios** (ex.: `"POC\\administrator"`) |
| `morpheus_access_token` | Token de acesso para autenticação (se utilizado, deixe username/password em branco) |
| `morpheus_insecure` | `true` para ignorar validação SSL em ambientes de lab. `false` em produção |

### B. Cloud, Group e Integração Git

| Parâmetro | Descrição |
|---|---|
| `morpheus_cloud_id` | ID da Cloud GCP no Morpheus (Infrastructure > Clouds) |
| `morpheus_group_id` | ID do Group associado à Cloud (Infrastructure > Groups) |
| `integration_id` | ID da integração Git/SCM (Administration > Integrations) |
| `repository_id` | ID do repositório Git sincronizado (Provisioning > Code > Repositories) |
| `version_ref` | Branch ou Tag do Git (ex.: `main`) |
| `working_path` | Caminho do manifesto Terraform (`PoCs/gcp-create-vm`) |
| `terraform_version` | Versão do Terraform executada pelo runner nativo (ex.: `1.6.0`) |

### C. Metadados do App Blueprint e Cypher

| Parâmetro | Descrição |
|---|---|
| `blueprint_name` | Nome **único** exibido no catálogo (ex.: `gcp-create-vm-native`) |
| `blueprint_description` | Descrição curta da aplicação |
| `blueprint_category` | Categoria de organização (ex.: `gcp-compute`) |
| `blueprint_visibility` | Visibilidade: `private` ou `public` |
| `cypher_secret_key` | Caminho do segredo no Cypher (ex.: `tfvars/gcp-create-vm-poc`). **Criado automaticamente** |

### D. Customização Opcional dos Rótulos (Labels)

Permite personalizar os títulos dos campos no formulário do Morpheus Data (`label_*`):
- `label_vm_name`, `label_machine_series`, `label_machine_type_override`, `label_disk_size_gb`, etc.
- Consulte a lista completa em [`terraform.tfvars-SAMPLE`](./terraform.tfvars-SAMPLE).

### E. Parâmetros da VM GCP (Formulário do Self-Service)

Se descomentados, os campos abrirão pré-preenchidos; se mantidos comentados, abrirão em branco:

| Parâmetro | Descrição |
|---|---|
| `poc_name` | Nome lógico da PoC para tagging |
| `project_id` | ID do projeto GCP |
| `gcp_credentials` | Conteúdo JSON da chave da Service Account |
| `region` / `zone` | Região e zona GCP |
| `vm_name` | Nome da instância Compute Engine |
| `machine_series` / `machine_type_override` | Identificadores nativos GCP (ex.: `e2`, `e2-micro`) |
| `vcpu_count` / `memory_gb` | vCPUs e RAM |
| `disk_type` / `disk_size_gb` | Tipo e tamanho do disco |
| `boot_image_project` / `boot_image_family` | Imagem nativa GCP |
| `assign_external_ip` | IP público externo (`true`/`false`) |
| `ssh_username` / `ssh_public_key` | Usuário Linux e chave pública SSH |
| `network_name` / `subnetwork_name` | VPC e Subnet |
| `allowed_http_cidr` / `allowed_ssh_cidr` | CIDRs para firewall (portas 80 e 22) |
| `use_metadata_ssh_keys` | Injetar chave SSH via metadado da instância |
| `user_groups` | Grupos Linux adicionais (ex.: `sudo`) |

---

## 7. Guia de Resolução de Problemas Comuns (Troubleshooting)

### 1. Bloqueio de Org Policy na Criação de Chaves GCP (`constraints/iam.disableServiceAccountKeyCreation`)

- **Sintoma**: `FAILED_PRECONDITION: Key creation is not allowed on this service account`.
- **Causa**: Política de organização no GCP proíbe a geração de chaves privadas JSON para Service Accounts.
- **Solução**: Desative a restrição no projeto executando:
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
  Aguarde ~60 segundos e tente criar a chave novamente.

### 2. `Error 412: Constraint constraints/compute.vmExternalIpAccess violated`

- **Sintoma**: Falha ao criar VM com IP externo (`conditionNotMet`).
- **Causa**: Org Policy bloqueando IP público.
- **Solução**: Execute `./scripts/setup-gcp-project.sh --project-id SEU_PROJECT_ID` para configurar `allowAll: true`.

### 3. `Error 403: Permission 'orgpolicy.policies.create' denied`

- **Sintoma**: Terraform ou Morpheus tenta criar uma Org Policy mas não tem permissão.
- **Causa**: A role `roles/orgpolicy.policyAdmin` não é suportada em nível de projeto.
- **Solução**: Configure a Org Policy previamente via `scripts/setup-gcp-project.sh` com uma conta administrativa. O código em `PoCs/gcp-create-vm` **não manipula Org Policies**.

### 4. `Integration / Repository ID invalid`

- **Sintoma**: `terraform apply` falha informando que a integração ou repositório não foi encontrado.
- **Causa**: IDs incorretos ou integração não sincronizada.
- **Solução**: Acesse **Administration > Integrations** e **Provisioning > Code > Repositories**, copie o ID da URL. Execute **Sync** no repositório.

### 5. Erros `401 Unauthorized` ou `403 Forbidden` no GCP

- **Sintoma**: Runner do Morpheus falha com erro de autorização.
- **Solução**:
  1. Habilite as APIs: `gcloud services enable compute.googleapis.com`.
  2. Garanta que a Service Account possui `roles/compute.admin` e `roles/iam.serviceAccountUser`.

### 6. `Cypher key already exists`

- **Sintoma**: Erro durante o `terraform apply`.
- **Solução**: Altere `cypher_secret_key` no `terraform.tfvars` ou remova a chave antiga em **Tools > Cypher**.

### 7. `Blueprint is in use by an app`

- **Sintoma**: `terraform destroy` falha ao tentar excluir o Blueprint.
- **Causa**: O Morpheus mantém registros de auditoria (soft-delete) de Apps anteriores.
- **Solução**: Desacople do Blueprint antigo:
  ```sh
  terraform state rm hpe_morpheus_app_blueprint_terraform.vm_nginx
  terraform state rm hpe_morpheus_catalog_item_app_blueprint.vm_nginx
  terraform apply -auto-approve  # Cria novo Blueprint com nome diferente
  ```

---

## 8. Referências e Próximos Passos

- 📖 **Guia Central de Implantação da PoC**: [`README.md`](./README.md)
- 🔄 **Gerenciamento de Estado Nativo e Drifts**: [`HOWTO-tfstate-drift.md`](./HOWTO-tfstate-drift.md)
- 🔐 **Documentação Oficial do Morpheus Cypher**: [Morpheus Cypher Docs](https://docs.morpheusdata.com/en/latest/tools/cypher/cypher.html)
- ☁️ **Documentação do Provider Google no Terraform**: [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
