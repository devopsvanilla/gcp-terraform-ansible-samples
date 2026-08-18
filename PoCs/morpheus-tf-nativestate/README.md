# PoC: Native Backend Terraform App Blueprint no Morpheus Data

## O que será implantado

Esta PoC utiliza o provedor oficial [`HPE/hpe`](https://registry.terraform.io/providers/HPE/hpe/latest) para criar e publicar no Morpheus Data um **App Blueprint Nativo de Terraform** (`hpe_morpheus_app_blueprint_terraform`) e o correspondente item de catálogo de Self-Service (`hpe_morpheus_catalog_item_app_blueprint`).

O Blueprint aponta para a PoC [`PoCs/gcp-create-vm`](../gcp-create-vm/README.md), que provisiona instâncias Compute Engine no GCP de forma declarativa, **sem dependências de Ansible ou Nginx**.

### Diferenciais da Arquitetura Nativa

- **Runner Nativo**: O Morpheus Data executa diretamente o ciclo de vida do Terraform (`init`, `plan`, `apply`) a partir do repositório Git vinculado.
- **Gerenciamento do Estado (`tfstate`) no Cypher**: O arquivo `.tfstate` é mantido e criptografado nativamente no **Morpheus Cypher**, dispensando buckets externos (GCS). Para instruções de como extrair esse estado e gerenciar *drifts*, veja [`HOWTO-tfstate-drift.md`](./HOWTO-tfstate-drift.md).
- **Injeção de Parâmetros via Cypher (`tfvar_secret`)**: Os valores das variáveis são gravados em um segredo do Cypher (`hpe_morpheus_cypher_secret`) e injetados automaticamente no plano do Terraform.
- **Formulário Amigável de Provisionamento**: Cada parâmetro da VM é exposto como um campo individual (Option Types) no Self-Service.
- **Isolamento de Estado**: Cada pedido no Catálogo provisiona 1 VM individual com seu próprio App Instance e `tfstate` isolado.

### Recursos Provisionados no GCP ao Executar o App Blueprint

Quando um usuário solicita o App Blueprint no catálogo, a engine nativa do Terraform executa o manifesto [`PoCs/gcp-create-vm`](../gcp-create-vm/README.md) e provisiona:

1. **Instância de VM no Google Compute Engine (GCE)**:
   - Máquina virtual GCP (ex.: `e2-micro` ou conforme formulário).
   - Disco de boot Persistent Disk (`pd-standard` de 30 GB ou conforme formulário) com a distribuição Linux escolhida (ex.: Debian 12).
   - Endereço IP público externo (quando `assign_external_ip = true`).
   - Injeção da chave pública SSH via metadados e `metadata_startup_script` para criação de usuário, grupos e permissões.

2. **Regras de Firewall na VPC GCP**:
   - Liberação de tráfego de entrada HTTP na porta `80` a partir do CIDR configurado (`allowed_http_cidr`).
   - Liberação de tráfego de entrada SSH na porta `22` a partir do CIDR de administração (`allowed_ssh_cidr`).

3. **Instância de Aplicação (App Instance) no Morpheus Data**:
   - Criação do objeto App Instance com monitoramento de status e `.tfstate` armazenado no Cypher.

---

## Pré-requisitos

### 1. Ferramentas no host de execução

| Ferramenta | Versão | Obrigatório | Uso |
|---|---|---|---|
| **Terraform CLI** | >= 1.6.0 | ✅ | Aplicar a automação de gestão do Morpheus Data |
| **gcloud CLI** | Última estável | ✅ | Preparação do projeto GCP (APIs, IAM, Org Policy) via `scripts/setup-gcp-project.sh` |
| **git** | Qualquer | ✅ | Versionamento e push para o repositório remoto |

> ⚠️ **Importante:** O runner nativo do Morpheus Data **não possui** `gcloud`, `ansible-playbook` nem outras ferramentas CLI no PATH. Todo código executado dentro do Blueprint deve ser autossuficiente, utilizando exclusivamente o provider Terraform do Google e `metadata_startup_script`. **Nunca use `local-exec` provisioners que dependam de ferramentas CLI** no código apontado pelo Blueprint.

### 2. Morpheus Data

- Instância do Morpheus Data acessível com credenciais (Username/Password ou Access Token).
- Permissões no Morpheus para gerenciar:
  - **Blueprints** (Library > Blueprints): criar/editar App Blueprints.
  - **Catalog Items** (Library > Catalog Items): publicar itens de Self-Service.
  - **Option Types** (Library > Option Types): criar campos de formulário.
  - **Cypher** (Tools > Cypher): ler/escrever segredos.
  - **Integrations** (Administration > Integrations): gerenciar integrações Git.

### 3. Integração Git no Morpheus Data

- Repositório sincronizado no Morpheus (obtenha os IDs de `integration_id` e `repository_id` na console em *Administration > Integrations* ou via API).
- O repositório deve conter o diretório `PoCs/gcp-create-vm`.

### 4. Projeto GCP e Credenciais

#### Permissões IAM da Service Account

A Service Account utilizada pelo Morpheus para provisionar VMs precisa das seguintes roles:

| Role IAM | Recurso | Finalidade |
|---|---|---|
| `roles/compute.admin` | Projeto | Criar/gerenciar instâncias Compute Engine, discos e regras de firewall |
| `roles/iam.serviceAccountUser` | Projeto | Associar Service Accounts às instâncias criadas |

> **Nota sobre Org Policies:** A role `roles/orgpolicy.policyAdmin` **não é suportada em nível de projeto** (`INVALID_ARGUMENT`). Para gerenciar Org Policies como `compute.vmExternalIpAccess`, use o script `scripts/setup-gcp-project.sh` com uma conta administrativa que tenha permissão organizacional, **antes** de executar o Blueprint.

#### APIs GCP necessárias

Habilite com o script `scripts/setup-gcp-project.sh` ou manualmente:

```bash
gcloud services enable \
  compute.googleapis.com \
  orgpolicy.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  serviceusage.googleapis.com \
  --project=SEU_PROJECT_ID
```

#### Org Policy `compute.vmExternalIpAccess`

Se o projeto GCP tiver a restrição `constraints/compute.vmExternalIpAccess` ativa (comum em organizações corporativas), a criação de VMs com IP externo falhará com erro `412 conditionNotMet`. Para resolver, execute o script de setup **antes** do primeiro provisionamento:

```bash
./scripts/setup-gcp-project.sh --project-id SEU_PROJECT_ID
```

O script configura `allowAll: true` para o projeto, permitindo que qualquer VM receba IP externo.

> 📌 **Guia Complementar:** Para detalhes sobre Service Account, credenciais e integração GitHub, consulte [`HOWTO-gcloud-connect.md`](./HOWTO-gcloud-connect.md).

---

## Como implantar

### Passo 1: Acessar o diretório da PoC

```sh
cd PoCs/morpheus-tf-nativestate
```

### Passo 2: Preparar o arquivo de variáveis `terraform.tfvars`

Crie o seu arquivo de variáveis a partir do modelo [`terraform.tfvars-SAMPLE`](./terraform.tfvars-SAMPLE):

```sh
cp terraform.tfvars-SAMPLE terraform.tfvars
```

### Passo 3: Configurar os parâmetros do `terraform.tfvars`

Edite o arquivo `terraform.tfvars` preenchendo as seções descritas abaixo.

#### A. Conexão com o Morpheus Data

| Parâmetro | Descrição |
|---|---|
| `morpheus_url` | URL completa da console (ex.: `https://morpheus.seu-dominio.com`) |
| `morpheus_username` / `morpheus_password` | Credenciais de usuário/senha. Use `\\` duplo para domínios: `"POC\\administrator"` |
| `morpheus_access_token` | Alternativa via Access Token (se utilizado, deixe username/password em branco) |
| `morpheus_insecure` | `true` para certificados autoassinados em lab/PoC, `false` em produção |

#### B. Cloud, Group e Integração Git

| Parâmetro | Descrição | Como obter |
|---|---|---|
| `morpheus_cloud_id` | ID da Cloud GCP no Morpheus | Infrastructure > Clouds > observe o ID na URL |
| `morpheus_group_id` | ID do Group associado | Infrastructure > Groups > observe o ID na URL |
| `integration_id` | ID da integração Git/SCM | Administration > Integrations > ID na URL (ex.: `/admin/integrations/15/code` → `15`) |
| `repository_id` | ID do repositório Git | Provisioning > Code > Repositories > ID na URL (ex.: `/provisioning/code/repos/63` → `63`) |
| `version_ref` | Branch do Git (ex.: `main`) | — |
| `working_path` | Caminho do manifesto Terraform | `PoCs/gcp-create-vm` |
| `terraform_version` | Versão do Terraform no runner | `1.6.0` |

#### C. Metadados do Blueprint e Cypher

| Parâmetro | Descrição |
|---|---|
| `blueprint_name` | Nome único exibido no catálogo (ex.: `gcp-create-vm-native`) |
| `blueprint_description` | Descrição do Blueprint |
| `blueprint_category` | Categoria de organização (ex.: `gcp-compute`) |
| `cypher_secret_key` | Caminho no Cypher para as tfvars (ex.: `tfvars/gcp-create-vm-poc`) |

> ⚠️ **O `blueprint_name` deve ser único no Morpheus.** Se já existir um Blueprint com o mesmo nome (mesmo que inativo), o `terraform apply` falhará com `Name must be unique`. Veja a seção [Erros Comuns](#guia-de-erros-comuns).

#### D. Parâmetros da VM GCP

- Se descomentados no `terraform.tfvars`, os campos abrirão **pré-preenchidos** no formulário do Self-Service.
- Se mantidos comentados (`#`), abrirão **em branco** exigindo preenchimento.
- Todos os campos são obrigatórios no formulário, exceto `subnetwork_name` e `user_groups`.

#### E. Customização de Rótulos (Labels)

Os títulos dos campos do formulário podem ser personalizados via variáveis `label_*`. Consulte o [`terraform.tfvars-SAMPLE`](./terraform.tfvars-SAMPLE) para a lista completa.

### Passo 4: Executar a automação

```sh
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

### Passo 5: Sincronizar o repositório Git no Morpheus

Após o `terraform apply`, acesse o Morpheus:

1. Vá em **Administration > Integrations**.
2. Clique em **Sync** no repositório Git para indexar o branch `main` atualizado com a pasta `PoCs/gcp-create-vm`.

---

## Como conferir a implantação

1. **Verificação na Console do Morpheus Data**:
   - **Provisioning > Blueprints**: Confirme a presença do Blueprint (tipo **Terraform**).
   - **Tools > Cypher**: Verifique a criação do segredo `tfvars/<cypher_secret_key>`.
   - **Self-Service > Catalog**: Localize o item publicado.

2. **Teste de Provisionamento no Self-Service**:
   - Clique em **Order** no item de catálogo.
   - Preencha os campos obrigatórios e solicite a App.
   - Acompanhe em **Provisioning > Apps** (aba **History / Logs**).

---

## Como descomissionar

### Remover recursos do Morpheus (Blueprint, Catalog Item, Option Types, Cypher Secrets)

```sh
terraform destroy -auto-approve
```

> ⚠️ **Se o `destroy` falhar** com `Blueprint is in use by an app`, consulte a seção [Erros Comuns](#8-blueprint-is-in-use-by-an-app).

### Remover VMs provisionadas via Catálogo

Acesse **Provisioning > Apps**, selecione a aplicação e clique em **Delete App**. O runner nativo executará `terraform destroy` usando o `tfstate` do Cypher.

---

## Guia de erros comuns

### 1. `NullPointerException: Cannot get property 'createServer' on null object`

- **Contexto**: Ao solicitar um App Blueprint no Catálogo do Morpheus.
- **Causa**: O `app_spec` do item de catálogo não contém `group.id` e/ou `cloud.id`. O Morpheus precisa desses IDs para resolver a Cloud de destino durante `TerraformProvisionService.prepareApp`.
- **Solução**: Verifique se o [`catalog_item.tf`](./catalog_item.tf) contém:
  ```yaml
  group:
    id: <morpheus_group_id>
  cloud:
    id: <morpheus_cloud_id>
  ```

### 2. `Name must be unique` ao criar o Blueprint

- **Contexto**: `terraform apply` tenta criar um Blueprint cujo nome já existe.
- **Causa**: O Morpheus requer nomes de Blueprint únicos. Se um Blueprint anterior com o mesmo nome já existir (mesmo que inativo ou órfão), a API rejeita a criação.
- **Solução**:
  - **Opção A**: Altere o `blueprint_name` no `terraform.tfvars` para um nome inédito.
  - **Opção B**: Importe o Blueprint existente para o estado do Terraform:
    ```sh
    terraform import hpe_morpheus_app_blueprint_terraform.vm_nginx <ID_DO_BLUEPRINT>
    terraform apply -auto-approve
    ```

### 3. `Error 412: Constraint constraints/compute.vmExternalIpAccess violated`

- **Contexto**: Criação de VM com IP externo no GCP.
- **Causa**: A Org Policy `constraints/compute.vmExternalIpAccess` do projeto GCP bloqueia a criação de VMs com IP público.
- **Solução**: Execute o script de setup do projeto **com uma conta administrativa** que tenha permissão na organização:
  ```bash
  ./scripts/setup-gcp-project.sh --project-id SEU_PROJECT_ID
  ```
  O script aplica `allowAll: true` na Org Policy do projeto.

### 4. `Error 403: Permission 'orgpolicy.policies.create' denied`

- **Contexto**: Terraform tenta criar/modificar uma Org Policy.
- **Causa**: A Service Account do Morpheus (`morpheus-tf-runner`) não tem permissão para gerenciar Org Policies. A role `roles/orgpolicy.policyAdmin` **não é suportada em nível de projeto** (`INVALID_ARGUMENT`).
- **Solução**: **Não** gerencie Org Policies pelo Terraform executado dentro do Morpheus. Configure a Org Policy previamente via `scripts/setup-gcp-project.sh` com uma conta que tenha permissão organizacional. O código em `PoCs/gcp-create-vm` **não** manipula Org Policies.

### 5. `local-exec provisioner error: gcloud não encontrado / ansible-playbook não encontrado`

- **Contexto**: Execução de provisioners `local-exec` dentro do runner do Morpheus.
- **Causa**: O container runner do Morpheus **não possui** `gcloud`, `ansible-playbook` nem outras ferramentas CLI no PATH.
- **Solução**: **Nunca use provisioners `local-exec` que dependam de ferramentas CLI** no código executado pelo Morpheus. Use:
  - `metadata_startup_script` para configuração pós-boot da VM.
  - Provider Terraform nativo do Google para operações de API.
  - `metadata.ssh-keys` para injeção de chaves SSH.

### 6. `Validation Error: rejected value [vm-nginx-poc] - must be unique`

- **Contexto**: Ao solicitar um App no Catálogo do Morpheus.
- **Causa**: O campo `name` do formulário (`customOptions.name`) foi preenchido com um nome já existente no Morpheus (mesmo de Apps anteriores já excluídas — o Morpheus faz soft-delete).
- **Solução**: Use um nome de VM diferente a cada pedido (ex.: `vm-gcp-01`, `vm-gcp-02`, etc.). Nomes de Apps anteriores ficam reservados no banco de dados do Morpheus para auditoria.

### 7. `Error: Cypher key already exists`

- **Causa**: O caminho `cypher_secret_key` já está em uso no Cypher.
- **Solução**: Altere a variável `cypher_secret_key` no `terraform.tfvars` (ex.: `tfvars/gcp-create-vm-poc-v2`) ou remova o segredo antigo via **Tools > Cypher**.

### 8. `Blueprint is in use by an app` (ao executar `terraform destroy`)

- **Contexto**: `terraform destroy` tenta excluir o Blueprint, mas o Morpheus bloqueia.
- **Causa**: O Morpheus mantém **registros de auditoria (soft-delete)** de todas as Apps já criadas a partir desse Blueprint. Mesmo com todas as Apps excluídas pela UI, os registros históricos impedem a exclusão do Blueprint.
- **Solução**: Desacople o Terraform do Blueprint existente sem tentar excluí-lo:
  ```sh
  # Remove os recursos do estado local do Terraform (não tenta excluir no Morpheus)
  terraform state rm hpe_morpheus_app_blueprint_terraform.vm_nginx
  terraform state rm hpe_morpheus_catalog_item_app_blueprint.vm_nginx

  # Cria um novo Blueprint com nome diferente
  # (ajuste blueprint_name no terraform.tfvars para um nome inédito)
  terraform apply -auto-approve
  ```

### 9. `Invalid escape sequence` (barra invertida no username)

- **Contexto**: Ao definir `morpheus_username` com domínio (ex.: `POC\administrator`).
- **Causa**: O parser HCL interpreta `\a` como escape inválido.
- **Solução**: Use barra invertida dupla:
  ```hcl
  morpheus_username = "POC\\administrator"
  ```

### 10. `Integration / Repository ID invalid`

- **Causa**: Os valores de `integration_id` ou `repository_id` no `terraform.tfvars` não existem no Morpheus.
- **Solução**: Acesse **Administration > Integrations** (para `integration_id`) e **Provisioning > Code > Repositories** (para `repository_id`). Copie o ID numérico da URL do navegador. Após corrigir, execute **Sync** no repositório.

---

## Diagnóstico e troubleshooting

### Checklist de diagnóstico rápido

Quando um pedido no Catálogo falhar, siga este checklist:

1. **Verificar o log do App Instance**:
   - Vá em **Provisioning > Apps**, abra o App criado e acesse a aba **History** ou **Logs**.
   - Copie a mensagem de erro completa.

2. **Verificar o Blueprint**:
   - Em **Library > Blueprints**, confirme que o Blueprint aponta para o `working_path` correto (`PoCs/gcp-create-vm`).
   - Verifique que o `tfvar_secret` no Blueprint aponta para um segredo existente no Cypher.

3. **Verificar os segredos no Cypher**:
   - Em **Tools > Cypher**, localize a chave `tfvars/<cypher_secret_key>`.
   - Valide que o conteúdo JSON contém todas as variáveis esperadas (especialmente `gcp_credentials`, `project_id`, `region`, `zone`).

4. **Verificar a integração Git**:
   - Em **Administration > Integrations**, confirme que o repositório está sincronizado (botão **Sync**).
   - Confirme que o branch (`version_ref`) contém o diretório `PoCs/gcp-create-vm` com todos os arquivos `.tf`.

5. **Verificar permissões no GCP**:
   - Confirme que a Service Account tem `roles/compute.admin` e `roles/iam.serviceAccountUser`.
   - Confirme que a Org Policy `compute.vmExternalIpAccess` está configurada com `allowAll: true`.

### Logs e APIs úteis

```bash
# Listar Apps no Morpheus via API (PowerShell com curl.exe)
$authJson = curl.exe -sk "https://MORPHEUS_URL/oauth/token" -d "grant_type=password&scope=write&client_id=morph-api" -d "username=USUARIO" --data-urlencode "password=SENHA"
$token = ($authJson | ConvertFrom-Json).access_token
$apps = curl.exe -sk -H "Authorization: Bearer $token" "https://MORPHEUS_URL/api/apps?max=50"
($apps | ConvertFrom-Json).apps | ForEach-Object { "$($_.id) - $($_.name) - $($_.status)" }

# Deletar uma App com force=true (substitua o ID)
curl.exe -sk -X DELETE -H "Authorization: Bearer $token" "https://MORPHEUS_URL/api/apps/<ID>?force=true"

# Verificar Blueprint por ID
curl.exe -sk -H "Authorization: Bearer $token" "https://MORPHEUS_URL/api/blueprints/<ID>"
```

---

## Referências

- 📖 **PoC de Terraform puro (GCP)**: [`PoCs/gcp-create-vm/README.md`](../gcp-create-vm/README.md)
- 🔐 **Conectividade GCP e GitHub**: [`HOWTO-gcloud-connect.md`](./HOWTO-gcloud-connect.md)
- 🔄 **Gerenciamento de Estado Nativo e Drifts**: [`HOWTO-tfstate-drift.md`](./HOWTO-tfstate-drift.md)
- 🔐 **Documentação Oficial do Morpheus Cypher**: [Morpheus Cypher Docs](https://docs.morpheusdata.com/en/latest/tools/cypher/cypher.html)
- ☁️ **Terraform GCP Provider**: [Terraform GCP Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)
- 🏢 **Terraform HPE Morpheus Provider**: [HPE Provider](https://registry.terraform.io/providers/HPE/hpe/latest)