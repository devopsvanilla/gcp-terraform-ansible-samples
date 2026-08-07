# PoC: Native Backend Terraform App Blueprint no Morpheus Data

## O que será implantado

Esta PoC utiliza o provedor oficial [`HPE/hpe`](https://registry.terraform.io/providers/HPE/hpe/latest) para criar e publicar no Morpheus Data um **App Blueprint Nativo de Terraform** (`hpe_morpheus_app_blueprint_terraform`) e o seu correspondente item de catálogo de Self-Service (`hpe_morpheus_catalog_item_app_blueprint`).

### Diferenciais da Arquitetura Nativa:
- **Runner Nativo**: O Morpheus Data executa diretamente o ciclo de vida do Terraform (`init`, `plan`, `apply`) a partir do repositório Git vinculado.
- **Gerenciamento do Estado (`tfstate`) no Cypher**: O arquivo de estado `.tfstate` é mantido e criptografado nativamente no **Morpheus Cypher**, dispensando a necessidade de buckets externos no Google Cloud Storage (GCS) ou arquivos de estado locais.
- **Injeção de Parâmetros via Cypher (`tfvar_secret`)**: Os valores das variáveis do `terraform.tfvars` são gravados em um segredo do Cypher (`hpe_morpheus_cypher_secret`) e injetados automaticamente no plano do Terraform.
- **Formulário Amigável de Provisionamento**: Cada parâmetro da VM (`vm_name`, `machine_type_override`, `disk_size_gb`, `assign_external_ip`, `ssh_username`, `ssh_public_key`, `network_name`, `allowed_ssh_cidr`, etc.) é exposto como um campo individual e amigável (Option Types) no Self-Service.
- **Obrigatoriedade e Rótulos Customizáveis**: Todos os campos do formulário são marcados como obrigatórios (com exceção de `subnetwork_name`), e os rótulos de cada campo exibidos na interface gráfica do Morpheus podem ser totalmente customizados via `terraform.tfvars`.
- **Isolamento de Estado**: Cada pedido no Catálogo provisiona 1 VM individual com seu próprio App Instance e `tfstate` isolado no Cypher.

### Recursos Provisionados no GCP ao Executar o App Blueprint:
Quando um usuário solicita o App Blueprint no catálogo do Morpheus Data, a engine nativa do Terraform executa o manifesto [`PoCs/vm-nginx-terraform-ansible`](../vm-nginx-terraform-ansible/README.md) utilizando os **identificadores nativos das APIs do GCP** (sem exigir a criação prévia de nenhum template no Morpheus Data) e provisiona automaticamente:

1. **Instância de VM no Google Compute Engine (GCE)**:
   - Uma máquina virtual GCP (ex.: `e2-micro` ou conforme especificado no formulário).
   - Disco de boot Persistent Disk (`pd-standard` de 30 GB ou conforme formulário) com a distribuição Linux escolhida (ex.: Debian 12).
   - Endereço IP público externo (quando `assign_external_ip = true`).
   - Injeção da chave pública SSH nos metadados para acesso administrativo.

2. **Regras de Firewall na VPC GCP**:
   - Liberação de tráfego de entrada HTTP na porta `80` a partir do CIDR configurado (`allowed_http_cidr`).
   - Liberação de tráfego de entrada SSH na porta `22` a partir do CIDR de administração (`allowed_ssh_cidr`).

3. **Política Organizacional GCP (Org Policy)**:
   - Aplicação e gestão da restrição `compute.vmExternalIpAccess` na Org Policy do projeto GCP (quando `manage_vm_external_ip_org_policy = true`), garantindo conformidade de acesso externo.

4. **Provisionamento de Aplicação com Ansible**:
   - Conexão SSH automática a partir do runner do Morpheus utilizando a chave privada recuperada com segurança do Cypher (`secret/ansible-private-key`).
   - Execução do playbook Ansible para instalação, inicialização e configuração do servidor Web **Nginx** na VM.

5. **Instância de Aplicação (App Instance) no Morpheus Data**:
   - Criação do objeto App Instance no Morpheus com monitoramento de status e o arquivo `.tfstate` armazenado nativamente no Morpheus Cypher.

---

## Pré-requisitos

1. **Terraform CLI `>= 1.6`** instalado localmente para aplicar esta automação de gestão do Morpheus Data.
2. Instância do **Morpheus Data** com credenciais (Username/Password ou Access Token) e permissão de gerenciamento de Blueprints, Option Types e itens de Catálogo.
3. **Integração Git no Morpheus Data**:
   - Repositório sincronizado no Morpheus (obtenha os IDs de `integration_id` e `repository_id` na console em *Administration > Integrations* ou via API/CLI do Morpheus).
   - O repositório deve conter o diretório `PoCs/vm-nginx-terraform-ansible`.
4. **Projeto GCP e Credenciais**:
   - O executor do Morpheus Data (ou o Service Account configurado na integração GCP do Morpheus) precisa ter permissão para criar Compute Engine, regras de VPC e Org Policies.

---

## Como implantar

### Passo 1: Acessar o diretório da PoC
```bash
cd PoCs/morpheus-tf-nativebackend
```

### Passo 2: Preparar o arquivo de variáveis `terraform.tfvars`
Crie o seu arquivo de variáveis a partir do modelo [`terraform.tfvars-SAMPLE`](./terraform.tfvars-SAMPLE):
```bash
cp terraform.tfvars-SAMPLE terraform.tfvars
```

### Passo 3: Configurar os parâmetros do `terraform.tfvars`
Edite o arquivo `terraform.tfvars` preenchendo as seções de configuração descritas abaixo:

#### A. Conexão com o Morpheus Data
- **`morpheus_url`**: URL completa da console do Morpheus Data (ex.: `https://morpheus.seu-dominio.com`).
- **`morpheus_username` / `morpheus_password`**: Credenciais de usuário/senha administrativa ou de automação no Morpheus.
- **`morpheus_access_token`**: Alternativa para autenticação via Access Token (se utilizado, deixe username/password em branco).
- **`morpheus_insecure`**: Defina como `true` para ignorar a validação de certificados SSL/TLS autoassinados em ambientes de laboratório/PoC. Em produção com SSL confiável, defina como `false`.

#### B. Integração com o Repositório Git
- **`integration_id`**: ID numérico da integração SCM/Git configurada no Morpheus Data (*Administration > Integrations*).
- **`repository_id`**: ID numérico do repositório Git sincronizado no Morpheus Data.
- **`version_ref`**: Branch ou Tag do Git que contém o código da aplicação (ex.: `main`).
- **`working_path`**: Caminho do manifesto Terraform alvo dentro do repositório (`PoCs/vm-nginx-terraform-ansible`).
- **`terraform_version`**: Versão do Terraform utilizada pelo runner nativo do Morpheus (ex.: `1.6.0`).

#### C. Metadados do Blueprint e Cypher
- **`blueprint_name`**: Nome exibido para a aplicação no catálogo do Morpheus (ex.: `vm-nginx-terraform-ansible-native`).
- **`blueprint_description`**: Descrição do Blueprint exibida no catálogo.
- **`blueprint_category`**: Categoria de organização no catálogo (ex.: `terraform-ansible-samples`).
- **`blueprint_visibility`**: Visibilidade do Blueprint (`private` ou `public`).
- **`cypher_secret_key`**: Caminho do segredo no Cypher onde as `tfvars` serão armazenadas (ex.: `tfvars/vm-nginx-poc`). **Este segredo é criado automaticamente pelo `terraform apply`**.

#### D. Customização Opcional dos Rótulos (Labels) dos Campos
- Você pode personalizar os títulos/rótulos exibidos acima de cada campo na interface do Morpheus Data definindo as variáveis `label_*` no `terraform.tfvars`:
  - `label_vm_name`: Rótulo do campo Nome da VM.
  - `label_machine_series` / `label_machine_type_override`: Rótulos da série e tipo de máquina.
  - `label_disk_size_gb`: Rótulo do tamanho do disco.
  - `label_subnetwork_name`: Rótulo do campo de subnet VPC (ex.: `Subnet VPC (Opcional - deixe vazio para utilizar a sub-rede padrão da região)`).
  - Demais rótulos `label_*`: Consulte a lista completa em [`terraform.tfvars-SAMPLE`](./terraform.tfvars-SAMPLE).

#### E. Parâmetros Padrão da VM GCP (Valores do Formulário)
- **Comportamento dos Campos no Formulário**:
  - **Se mantidos comentados (`#`)**: Os campos no formulário do Self-Service abrirão **em branco**, exigindo preenchimento pelo solicitante.
  - **Se descomentados**: Os campos abrirão **pré-preenchidos** no formulário com esses valores como padrão.
- **Obrigatoriedade**: Todos os campos são de preenchimento obrigatório no Morpheus Data, com exceção de `subnetwork_name` (opcional).
- **Lista de Parâmetros de VM**:
  - `vm_name`: Nome da VM GCP.
  - `machine_series` / `machine_type_override`: Identificadores nativos GCP (ex.: `e2`, `e2-micro`).
  - `vcpu_count` / `memory_gb`: vCPUs e RAM da instância.
  - `disk_type` / `disk_size_gb`: Tipo de disco (`pd-standard`) e tamanho em GB.
  - `boot_image_project` / `boot_image_family`: Imagem nativa GCP (`debian-cloud`, `debian-12`).
  - `assign_external_ip` / `manage_vm_external_ip_org_policy`: IP público e Org Policy (`true`/`false`).
  - `ssh_username` / `ssh_public_key`: Usuário Linux e chave pública SSH.
  - `network_name` / `subnetwork_name`: VPC e Subnet GCP.
  - `allowed_http_cidr` / `allowed_ssh_cidr`: Firewall GCP para portas 80 e 22.
  - `run_ansible` / `ansible_ssh_user`: Provisionamento do Nginx via Ansible.

#### F. Chave Privada SSH do Ansible (`ansible_private_key`)
- Fornecida no `terraform.tfvars` da automação via bloco multilinha `<<-EOT`:
  ```hcl
  ansible_private_key = <<-EOT
  -----BEGIN OPENSSH PRIVATE KEY-----
  b3BlbnNzaC1rZXktdjEAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW...
  -----END OPENSSH PRIVATE KEY-----
  EOT
  ```
- **Segurança**: O `terraform apply` salva essa chave no segredo criptografado `secret/ansible-private-key` no Cypher do Morpheus. O solicitante final no Catálogo **nunca visualiza ou precisa fornecer a chave privada no formulário**.

---

### Passo 4: Executar a automação no Terraform
1. Inicialize os provedores do Terraform:
   ```bash
   terraform init
   ```

2. Valide a sintaxe do projeto:
   ```bash
   terraform validate
   ```

3. Visualize os recursos que serão criados no Morpheus Data:
   ```bash
   terraform plan
   ```

4. Aplique a automação para criar os Option Types, Cypher Secrets e o App Blueprint:
   ```bash
   terraform apply -auto-approve
   ```

---

## Como conferir a implantação

1. **Verificação na Console do Morpheus Data**:
   - Acesse **Provisioning > Blueprints** e confirme a presença do Blueprint `vm-nginx-terraform-ansible-native` (tipo **Terraform**).
   - Acesse **Tools > Cypher** e verifique a criação dos segredos:
     - `tfvars/vm-nginx-poc`: Carga útil das variáveis `tfvars`.
     - `secret/ansible-private-key`: Segredo seguro da chave privada SSH.
   - Acesse **Self-Service > Catalog** e localize o item `vm-nginx-terraform-ansible-native`.

2. **Teste de Provisionamento no Self-Service**:
   - Clique em **Order** no item de catálogo.
   - Verifique se o formulário exibe os campos amigáveis (`Nome da VM`, `Tipo de Máquina`, `Tamanho do Disco`, `IP Público`, `Chave Pública SSH`, `Rede VPC`, etc.) com os seus respectivos rótulos customizados.
   - Preencha os campos obrigatórios e solicite a App.
   - Acesse **Provisioning > Apps**, selecione a App criada e acompanhe a aba **History / Logs**. O Morpheus executará o runner Terraform nativo armazenando o `tfstate` no Cypher.

---

## Como descomissionar

1. Para remover o App Blueprint, o item de catálogo, os Option Types e os segredos do Cypher no Morpheus Data, execute:
   ```bash
   terraform destroy -auto-approve
   ```

2. Para descomissionar instâncias de VM provisionadas via Catálogo no Morpheus, acesse **Provisioning > Apps**, selecione a aplicação desejada e clique em **Delete App**. O runner nativo do Morpheus executará `terraform destroy` utilizando o `tfstate` armazenado no Cypher.

---

## Guia de erros comuns

### 1. `Error: Integration / Repository ID invalid`
- **Causa**: Os valores de `integration_id` ou `repository_id` informados no `terraform.tfvars` não existem na sua instância do Morpheus.
- **Solução**: Acesse a console web do Morpheus em **Administration > Integrations**, abra a integração Git/GitHub e copie o ID numérico da URL ou inspecione via API.

### 2. `Error: Cypher key already exists`
- **Causa**: O caminho informado em `cypher_secret_key` já está em uso no Cypher.
- **Solução**: Altere a variável `cypher_secret_key` no `terraform.tfvars` (ex.: `tfvars/vm-nginx-poc-v2`) ou remova o segredo antigo via console web do Morpheus (**Tools > Cypher**).

### 3. `Failed to load tfvars from Cypher during provision`
- **Causa**: A engine do Morpheus não conseguiu ler o segredo apontado por `tfvar_secret`.
- **Solução**: Verifique se o formato da chave no `cypher.tf` começa com `tfvars/` e se o usuário do Morpheus possui permissão de leitura nos segredos do Cypher.

### 4. `Terraform execution error in Morpheus App Instance`
- **Causa**: Credenciais do Google Cloud ausentes ou inválidas no runner do Morpheus Data.
- **Solução**: Certifique-se de que a conta de serviço do GCP (Service Account) esteja configurada na integração Cloud do Morpheus ou que o Application Default Credentials (`ADC`) esteja ativo na máquina onde o Morpheus executa.
