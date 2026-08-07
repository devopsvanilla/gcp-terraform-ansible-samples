# Guia de Configuração e Conexão GCP / GitHub / Cypher - Morpheus Native Backend PoC

Este documento detalha todos os pré-requisitos, permissões do Google Cloud Platform (GCP), integração com GitHub, segredos no Morpheus Cypher e o preenchimento do arquivo [`terraform.tfvars`](./terraform.tfvars-SAMPLE) para a execução do **App Blueprint Nativo com Backend de Estado no Cypher** (`morpheus-tf-nativestate`).

> 📘 **Nota Central:** Este guia é específico sobre integrações e permissões. O documento principal sobre o funcionamento da automação, os recursos provisionados e o passo a passo de implantação via Terraform é o [`README.md`](./README.md).

---

## 1. Visão Geral da Integração

Nesta arquitetura **Native State**, o Morpheus Data atua diretamente como o orquestrador do ciclo de vida do Terraform (`init`, `plan`, `apply`, `destroy`), utilizando o código-fonte hospedado no repositório **GitHub** e armazenando o arquivo de estado (`.tfstate`) de forma segura e criptografada no **Morpheus Cypher**.

Para que essa automação funcione sem intervenções manuais, a infraestrutura exige quatro pilares de preparação:

1. **GCP Project & IAM**: Conta de serviço (Service Account) com roles adequadas para criar instâncias Compute Engine, regras de firewall VPC e ajustar Org Policies.
2. **GitHub SCM Integration**: Repositório vinculado no Morpheus Data para download automático do código Terraform.
3. **Morpheus Cypher**: Segredos configurados para injeção automática de variáveis (`tfvars/vm-nginx-poc`) e da chave privada SSH do Ansible (`secret/ansible-private-key`).
4. **Morpheus Provider (`terraform.tfvars`)**: Definição dos parâmetros da automação que aplicará o Blueprint e os Option Types no Morpheus Data.

---

## 2. Permissões e Recursos a Criar Antecipadamente no GCP

### Passo 1: Habilitar as APIs Necessárias no Projeto GCP

No projeto GCP onde a infraestrutura da VM será provisionada (substitua `SEU_PROJECT_ID` pelo ID do seu projeto GCP):

```bash
gcloud services enable \
  compute.googleapis.com \
  orgpolicy.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  --project=SEU_PROJECT_ID
```

### Passo 2: Criar a Service Account da Automação

Crie a Service Account no GCP que será utilizada pelo Morpheus Data para criar as VMs e Firewalls:

```bash
gcloud iam service-accounts create morpheus-tf-runner \
  --display-name="Morpheus Native Terraform Runner SA" \
  --project=SEU_PROJECT_ID
```

### Passo 3: Atribuir Roles IAM Necessárias

Conceda as permissões requeridas à Service Account no projeto GCP:

```bash
# Permissão para gerenciar instâncias Compute Engine, discos e regras de firewall VPC
gcloud projects add-iam-policy-binding SEU_PROJECT_ID \
  --member="serviceAccount:morpheus-tf-runner@SEU_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/compute.admin"

# Permissão para gerenciar a Org Policy compute.vmExternalIpAccess (caso manage_vm_external_ip_org_policy = true)
gcloud projects add-iam-policy-binding SEU_PROJECT_ID \
  --member="serviceAccount:morpheus-tf-runner@SEU_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/orgpolicy.policyAdmin"

# Permissão para associar Service Accounts às instâncias criadas
gcloud projects add-iam-policy-binding SEU_PROJECT_ID \
  --member="serviceAccount:morpheus-tf-runner@SEU_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"
```

### Passo 4: Gerar a Chave Privada JSON da Service Account

Crie o arquivo de chave privada em formato JSON:

```bash
gcloud iam service-accounts keys create gcp-key.json \
  --iam-account=morpheus-tf-runner@SEU_PROJECT_ID.iam.gserviceaccount.com
```

> ⚠️ **ATENÇÃO:** O arquivo `gcp-key.json` contém credenciais administrativas do GCP. Nunca versione este arquivo no Git.
>
> 💡 **Nota de Org Policy:** Se o comando acima falhar com o erro `FAILED_PRECONDITION: Key creation is not allowed on this service account`, o GCP possui uma política de organização bloqueando a criação de chaves (`constraints/iam.disableServiceAccountKeyCreation`). Veja como resolver na seção de [Troubleshooting](#7-guia-de-resolução-de-problemas-comuns-troubleshooting).

---

## 3. Formas de Conectar as Credenciais GCP no Morpheus Data

O Morpheus Data pode autenticar no GCP de três maneiras distintas:

### Método 1: Integração Cloud Nativa GCP no Morpheus (Recomendado)

1. Na console web do Morpheus Data, acesse **Infrastructure > Clouds**.
2. Clique em **+ Add** e selecione **Google Cloud Platform**.
3. Em **Credentials**, selecione `Local Credentials` ou `New Credentials`:
   - **Client Email**: E-mail da Service Account (`morpheus-tf-runner@SEU_PROJECT_ID.iam.gserviceaccount.com`).
   - **Private Key**: Chave privada com quebras de linha (`-----BEGIN PRIVATE KEY-----\n...`).
4. Para extrair esses valores com a formatação correta a partir do `gcp-key.json`, utilize o script auxiliar no repositório:
   ```bash
   ./scripts/extract-gcp-credentials.sh
   ```
5. Selecione o **Project ID** (`SEU_PROJECT_ID`) e a **Region** (`us-central1`).
6. Clique em **Save**.

### Método 2: Armazenamento da Chave no Cypher (GOOGLE_CREDENTIALS)

Caso o Morpheus execute as Tasks via scripts customizados do Terraform CLI, insira a chave JSON inteira no Cypher:

1. Acesse **Tools > Cypher > + Add**.
2. **Key**: `secret/gcp-terraform-ansible-samples`
3. **Type**: `Secret`
4. **Value**: Cole todo o conteúdo bruto do arquivo `gcp-key.json`.
5. **TTL**: `0`.
6. No script da Task, injete a variável de ambiente:
   ```bash
   export GOOGLE_CREDENTIALS='<%=cypher.read("secret/gcp-terraform-ansible-samples")%>'
   ```

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
  - *Exemplo*: Na URL `https://morpheus.cec.dev.br/admin/integrations/15/code`, o ID é **`15`**.
- **`repository_id`**: Acesse **Provisioning > Code > Repositories** (ou navegue pelos repositórios da integração) e observe o ID na URL ao abrir o repositório.
  - *Exemplo*: Na URL `https://morpheus.cec.dev.br/provisioning/code/repos/63`, o ID é **`63`**.

---

## 5. Estrutura e Configuração do Morpheus Cypher

Nesta PoC nativa, o Morpheus Cypher desempenha dois papéis fundamentais:

```
Estrutura de Chaves Cypher:
├── tfvars/vm-nginx-poc          <-- Armazena o payload das tfvars injetado no terraform plan/apply
└── secret/ansible-private-key   <-- Criptografa a chave privada SSH do Ansible para injeção segura
```

1. **`tfvars/vm-nginx-poc` (`cypher_secret_key`)**:
   - Criado automaticamente pela automação Terraform ([`cypher.tf`](./cypher.tf)).
   - Guarda o bloco HCL com os valores dos Option Types preenchidos no formulário do Self-Service.
   - O Morpheus lê esse segredo durante o provisionamento através da propriedade `tfvar_secret`.

2. **`secret/ansible-private-key`**:
   - Armazena a chave privada SSH fornecida na variável `ansible_private_key` no `terraform.tfvars`.
   - Quando `run_ansible = true`, o Terraform recupera este valor via `<%=cypher.read('secret/ansible-private-key')%>` nos metadados, evitando expor chaves privadas em texto puro.

---

## 6. Detalhamento dos Parâmetros do `terraform.tfvars-SAMPLE`

O arquivo [`terraform.tfvars-SAMPLE`](./terraform.tfvars-SAMPLE) é o modelo para a configuração da automação que cria o Blueprint no Morpheus Data. Abaixo está a explicação detalhada de cada seção:

### A. Conexão com o Morpheus Data

- **`morpheus_url`**: URL completa da console do Morpheus Data (ex.: `https://morpheus.seu-dominio.com`).
- **`morpheus_username` / `morpheus_password`**: Credenciais de usuário/senha com privilégios administrativos no Morpheus.
- **`morpheus_access_token`**: Token de acesso para autenticação (se utilizado, deixe username/password em branco).
- **`morpheus_insecure`**: Defina como `true` para ignorar a validação de certificados SSL autoassinados em ambientes de laboratório. Em produção com SSL confiável, defina como `false`.

### B. Integração Git no Morpheus Data

- **`integration_id`**: ID numérico da integração SCM/Git configurada no Morpheus Data (*Administration > Integrations*). Exemplo: na URL `https://morpheus.cec.dev.br/admin/integrations/15/code`, o ID é `15`.
- **`repository_id`**: ID numérico do repositório Git sincronizado no Morpheus Data (*Provisioning > Code > Repositories*). Exemplo: na URL `https://morpheus.cec.dev.br/provisioning/code/repos/63`, o ID é `63`.
- **`version_ref`**: Branch ou Tag do Git que contém o código da aplicação (ex.: `main`).
- **`working_path`**: Caminho relativo do manifesto Terraform dentro do repositório (`PoCs/vm-nginx-terraform-ansible`).
- **`terraform_version`**: Versão do Terraform executada pelo runner nativo do Morpheus (ex.: `1.6.0`).

### C. Metadados do App Blueprint e Cypher

- **`blueprint_name`**: Nome exibido para a aplicação no catálogo do Morpheus (ex.: `vm-nginx-terraform-ansible-native`).
- **`blueprint_description`**: Descrição curta da aplicação exibida no catálogo.
- **`blueprint_category`**: Categoria de organização no catálogo (ex.: `terraform-ansible-samples`).
- **`blueprint_visibility`**: Visibilidade do Blueprint (`private` ou `public`).
- **`cypher_secret_key`**: Caminho do segredo no Cypher onde as `tfvars` serão armazenadas (ex.: `tfvars/vm-nginx-poc`). **Criado automaticamente pelo `terraform apply`**.

### D. Customização Opcional dos Rótulos (Labels) dos Campos

Permite personalizar os títulos/rótulos exibidos acima de cada campo no formulário do Morpheus Data (`label_*`):
- `label_vm_name`: Rótulo do campo Nome da VM.
- `label_machine_series` / `label_machine_type_override`: Rótulos da série e tipo de máquina.
- `label_disk_size_gb`: Rótulo do tamanho do disco.
- `label_subnetwork_name`: Rótulo do campo de subnet VPC (ex.: `Subnet VPC (Opcional)`).
- *(Consulte a lista completa em [`terraform.tfvars-SAMPLE`](./terraform.tfvars-SAMPLE))*.

### E. Parâmetros Padrão da VM GCP (Formulário do Self-Service)

Se descomentados (`#`), os campos abrirão pré-preenchidos no formulário com estes valores como padrão. Se mantidos comentados, abrirão em branco exigindo preenchimento:

- `poc_name`: Nome lógico da solução para tagging e identificação interna.
- `project_id`: ID do projeto GCP onde os recursos serão criados.
- `region` / `zone`: Região e zona GCP padrão (ex.: `us-central1`, `us-central1-a`).
- `vm_name`: Nome padrão da instância Compute Engine.
- `machine_series` / `machine_type_override`: Identificadores nativos GCP (ex.: `e2`, `e2-micro`).
- `vcpu_count` / `memory_gb`: Quantidade de vCPUs e memória RAM em GB.
- `disk_type` / `disk_size_gb`: Tipo (`pd-standard`) e tamanho do disco em GB.
- `boot_image_project` / `boot_image_family`: Imagem nativa GCP (ex.: `debian-cloud`, `debian-12`).
- `assign_external_ip`: Define se a VM receberá um IP público externo (`true`/`false`).
- `manage_vm_external_ip_org_policy`: Gerencia a restrição `compute.vmExternalIpAccess` na Org Policy (`true`/`false`).
- `ssh_username` / `ssh_public_key`: Usuário Linux e chave pública SSH em formato OpenSSH.
- `network_name` / `subnetwork_name`: Nome da VPC e Subnet GCP.
- `allowed_http_cidr` / `allowed_ssh_cidr`: Firewall GCP para liberar portas 80 e 22.
- `use_metadata_ssh_keys`: Injeta chave SSH via metadado `ssh-keys` da instância (`true`/`false`).
- `run_ansible` / `ansible_ssh_user`: Habilitação e usuário SSH do provisionador Ansible.
- `ansible_wait_seconds` / `ansible_max_retries`: Configurações de retentativa e tempo de espera da conexão Ansible.

### F. Chave Privada SSH do Ansible (`ansible_private_key`)

Fornecida no `terraform.tfvars` da automação via bloco multilinha `<<-EOT`:

```hcl
ansible_private_key = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW...
-----END OPENSSH PRIVATE KEY-----
EOT
```

- **Segurança**: O `terraform apply` salva essa chave no segredo criptografado `secret/ansible-private-key` no Cypher do Morpheus. O solicitante final no Catálogo **nunca visualiza ou precisa fornecer a chave privada no formulário**.

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
  Aguarde cerca de 60 segundos e tente criar a chave novamente com `gcloud iam service-accounts keys create ...`.

### 2. `Error: Integration / Repository ID invalid` no Morpheus

- **Sintoma**: O `terraform apply` falha informando que a integração ou repositório não foi encontrado.
- **Causa**: Os valores de `integration_id` ou `repository_id` informados no `terraform.tfvars` não existem ou a integração GitHub não está sincronizada.
- **Solução**: Acesse **Administration > Integrations** (para `integration_id`) e **Provisioning > Code > Repositories** (para `repository_id`), abra o recurso desejado e copie o ID numérico da URL do navegador (ex.: `15` em `/admin/integrations/15/code` e `63` em `/provisioning/code/repos/63`). Em seguida, clique no botão **Sync Repository**.

### 3. Erros `401 Unauthorized` ou `403 Forbidden` no GCP

- **Sintoma**: O runner do Morpheus falha durante a execução da App Instance com erro de autorização nas APIs GCP.
- **Causa**: As APIs necessárias do GCP não estão ativadas ou a Service Account não possui as roles requeridas.
- **Solução**:
  1. Habilite as APIs: `gcloud services enable compute.googleapis.com orgpolicy.googleapis.com`.
  2. Garanta que a Service Account possui as roles `roles/compute.admin` e `roles/orgpolicy.policyAdmin`.

### 4. Bloqueio de Org Policy ao Atribuir IP Público (`constraints/compute.vmExternalIpAccess`)

- **Sintoma**: Falha ao criar a instância Compute Engine devido a bloqueio de IP público pela Org Policy.
- **Solução**: Garanta que a Service Account possui a role `roles/orgpolicy.policyAdmin` e que o parâmetro `manage_vm_external_ip_org_policy = true` está ativado no formulário.

### 5. `Error: Cypher key already exists` ou Falha ao Ler o Segredo

- **Sintoma**: Erro durante o `terraform apply` da automação ou falha na leitura de `tfvars` durante o provisionamento da App Instance.
- **Causa**: O caminho `cypher_secret_key` informado já está em uso ou o usuário do Morpheus não possui permissão no Cypher.
- **Solução**: Altere o caminho da chave em `cypher_secret_key` no `terraform.tfvars` (ex.: `tfvars/vm-nginx-poc-v2`) ou remova a chave antiga em **Tools > Cypher**.

---

## 8. Referências e Próximos Passos

- 📖 **Guia Central de Implantação da PoC**: [`README.md`](./README.md)
- 🔄 **Gerenciamento de Estado Nativo e Drifts**: [`HOWTO-tfstate-drift.md`](./HOWTO-tfstate-drift.md)
- 🔐 **Documentação Oficial do Morpheus Cypher**: [Morpheus Cypher Docs](https://docs.morpheusdata.com/en/latest/tools/cypher/cypher.html)
- ☁️ **Documentação do Provider Google no Terraform**: [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
