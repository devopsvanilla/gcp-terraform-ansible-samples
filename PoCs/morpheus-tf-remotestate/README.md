# PoC: App Blueprint no Morpheus Data para a PoC vm-nginx-terraform-ansible

## O que será implantado

Esta PoC usa o provider Terraform [`HPE/hpe`](https://registry.terraform.io/providers/HPE/hpe/latest)
para criar, no Morpheus Data, um item de catálogo de self-service (publicado
como **App Blueprint** para o solicitante final) que:

- exibe um **formulário** com os mesmos parâmetros aceitos por
  `scripts/add-vm-to-tfvars.sh` (chave e nome da VM, tipo de máquina, disco,
  imagem de boot, IP externo, usuário/chave SSH, rede, CIDRs de firewall,
  Org Policy e grupos do usuário remoto);
- ao ser executado, dispara uma **task de shell script** que:
  1. executa `scripts/add-vm-to-tfvars.sh` com os valores informados no
     formulário, adicionando a nova VM ao `terraform.tfvars` da PoC
     [`vm-nginx-terraform-ansible`](../vm-nginx-terraform-ansible/README.md);
  2. em seguida executa `terraform init`, `terraform validate` e
     `terraform apply -auto-approve` nesse mesmo manifesto.

### Por que não usar `hpe_morpheus_app_blueprint_terraform` diretamente

O provider HPE possui um recurso literalmente chamado `hpe_morpheus_app_blueprint_terraform`,
mas ele foi desenhado para que o **próprio Morpheus** execute um conteúdo
Terraform como a aplicação implantada (o blueprint É o Terraform). Ele não
oferece, de forma nativa, o fluxo "executar um script → depois aplicar um
manifesto Terraform separado" descrito nesta PoC.

A combinação de recursos abaixo é o equivalente funcional mais próximo do
comportamento pedido, e é o padrão recomendado pelo próprio provider para
"formulário de self-service que dispara uma automação":

| Recurso Terraform                        | Papel no Morpheus Data                                             |
|-------------------------------------------|---------------------------------------------------------------------|
| `hpe_morpheus_option_type_text/number/checkbox` | Cada campo do formulário exibido ao solicitante                |
| `hpe_morpheus_task_shell_script`          | O script que roda `add-vm-to-tfvars.sh` e o `terraform apply`        |
| `hpe_morpheus_workflow_operational`       | Agrupa os campos do formulário e a task, em ordem de execução       |
| `hpe_morpheus_catalog_item_workflow`      | Pública o workflow no catálogo de self-service (o "App Blueprint")   |

Todos os arquivos `.tf` desta PoC estão documentados com o objetivo de cada
recurso; consulte-os para o detalhamento de cada bloco.

## Estratégia de Armazenamento de Estado (`tfstate`)

Nesta arquitetura, adota-se o padrão de **backend local por padrão** com **sobreposição dinâmica (override)** para execuções remotas:

1. **Execuções Manuais / Locais (Desenvolvimento)**:
   O arquivo [`versions.tf`](../vm-nginx-terraform-ansible/versions.tf) **não declara nenhum bloco `backend`**. Com isso, qualquer execução direta (`terraform init` / `apply`) no computador do desenvolvedor armazena o estado no backend **local** (`terraform.tfstate`), sem exigir conexão ou criação de buckets no Google Cloud ou qualquer outro compatível.

2. **Execuções Automatizadas via Morpheus Data (Remoto / GCS)**:
   Quando a Shell Task [`add_vm_and_apply.sh`](./templates/add_vm_and_apply.sh) é disparada pelo Morpheus, ela gera temporariamente um arquivo de sobreposição chamado `backend_override.tf` contendo a declaração do backend GCS:

   ```hcl
   terraform {
     backend "gcs" {
       bucket = "tfstate-devopsvanilla-samples"
       prefix = "vm-nginx-terraform-ansible"
     }
   }
   ```

   Em seguida, o script executa `terraform init -reconfigure` para conectar ao bucket GCS e, ao término da execução, um `trap` remove automaticamente o arquivo `backend_override.tf`, mantendo o repositório limpo.

### Suporte a Outros Backends Remotos

Embora o script da PoC gere a configuração para o **Google Cloud Storage (`gcs`)**, a mesma estratégia de `override` permite alternar para **qualquer backend remoto oficial do Terraform** (AWS S3, Azure Blob, HashiCorp Consul, HTTP, etc.) apenas ajustando o bloco gerado no script.

### Comparativo com o Native State (Cypher)
Caso prefira não utilizar um bucket remoto (como GCS) e gerenciar o `tfstate` diretamente no cofre nativo do Morpheus Data (Cypher), consulte a PoC [`morpheus-tf-nativestate`](../morpheus-tf-nativestate/README.md) e o guia detalhado de recuperação de state e correção de drift em [`HOWTO-tfstate-drift.md`](../morpheus-tf-nativestate/HOWTO-tfstate-drift.md).


## Pré-requisitos

- Terraform `>= 1.6` e acesso à internet para baixar o provider `HPE/hpe >= 1.6.0`.
- Uma instância do Morpheus Data acessível, com um usuário/senha ou access
  token com permissão para criar option types, tasks, workflows e itens de
  catálogo.
- O host onde a **task** será executada (`task_execute_target`, padrão `local`
  = o próprio Morpheus; também suporta `remote` e `resource`) precisa ter:
  - O repositório Git sincronizado no Morpheus Data com o seu respectivo **ID de repositório** (informado em `task_repository_id` no `terraform.tfvars` ou via integração Git em `git_integration_name` / `git_repository_name`);
  - `bash`, `python3` (usado por `add-vm-to-tfvars.sh`), `terraform` e
    `gcloud`/ADC configurado com permissão para o projeto GCP alvo;
  - o bucket de state remoto da PoC `vm-nginx-terraform-ansible` já criado
    (`./scripts/create-tfstate-bucket.sh`), pois a task executa `terraform init`
    sem a flag `-migrate-state`.
- Se `task_execute_target = "remote"`, defina também `remote_target_host`,
  `remote_target_port`, `remote_target_username` e `remote_target_password`.
- Copie `terraform.tfvars-SAMPLE` para `terraform.tfvars` e preencha os
  valores reais (incluindo `task_repository_id`). **Nunca versione `terraform.tfvars` com credenciais.**

## Como implantar

1. Acesse o diretório `PoCs/morpheus`.
2. Copie o arquivo de exemplo e ajuste os valores:
   - `cp terraform.tfvars-SAMPLE terraform.tfvars`
3. Execute o fluxo padrão do Terraform:
   - `terraform init`
   - `terraform fmt`
   - `terraform validate`
   - `terraform plan`
4. Aplique os objetos no Morpheus Data:
   - `terraform apply`
5. No Morpheus Data, acesse **Self-Service > Catalog** e localize o item com
   o nome definido em `blueprint_name` (padrão `vm-nginx-terraform-ansible`).
6. Clique em **Order**, preencha o formulário com os mesmos dados que você
   passaria para `scripts/add-vm-to-tfvars.sh` (chave/nome da VM, tipo de
   máquina, disco, imagem, IP externo, SSH, rede, CIDRs, Org Policy e grupos)
   e confirme.

## Como conferir a implantação

- Confirmar os objetos criados via outputs Terraform:
  - `terraform output task_id`
  - `terraform output workflow_id`
  - `terraform output catalog_item_id`
  - `terraform output catalog_item_name`
- No Morpheus Data, em **Library > Workflows > Operational**, confirmar que
  o workflow aparece com a task e os option types associados.
- Após lançar o item de catálogo, acompanhar a execução em **Provisioning >
  History** (ou **Executions**) e revisar o log da task — ele deve mostrar
  a chamada a `add-vm-to-tfvars.sh` seguida de `terraform init`, `validate`
  e `apply`.
- Confirmar que a nova VM foi adicionada ao mapa `vms` do
  `PoCs/vm-nginx-terraform-ansible/terraform.tfvars` no host de execução.
- Confirmar que o `terraform apply` da PoC `vm-nginx-terraform-ansible` foi
  concluído com sucesso, usando os passos de "Como conferir a implantação"
  do [README dessa PoC](../vm-nginx-terraform-ansible/README.md#como-conferir-a-implantação).
- **Critério de sucesso**: o item de catálogo aparece no Morpheus Data, o
  formulário é exibido corretamente ao solicitante, e uma execução de teste
  do App Blueprint resulta em uma nova entrada em `vms` no `terraform.tfvars`
  e em uma VM provisionada com sucesso na GCP.

## Como descomissionar

- Para remover **apenas os objetos criados no Morpheus Data** por esta PoC
  (option types, task, workflow e item de catálogo):
  - `terraform destroy`
- Isso **não** destrói nenhuma VM provisionada na GCP através das execuções
  do App Blueprint. Para descomissionar as VMs criadas, siga a seção "Como
  descomissionar" do [README da PoC vm-nginx-terraform-ansible](../vm-nginx-terraform-ansible/README.md).
- Se preferir manter o App Blueprint mas impedir novos lançamentos, defina
  `enabled = false` em `catalog_item.tf` e aplique novamente, em vez de
  destruir os recursos.

## Guia de erros comuns

- **Erro de autenticação no provider (`401`/`403`)**: revise
  `morpheus_url`, `morpheus_username`/`morpheus_password` (ou
  `morpheus_access_token`) e `morpheus_tenant_subdomain` em `terraform.tfvars`.
- **Task falha com "Repositório não encontrado" ou "Script não encontrado
  ou não executável"**: confirme que `repo_path` aponta para uma cópia
  válida deste repositório no host de execução da task, e que
  `scripts/add-vm-to-tfvars.sh` tem permissão de execução (`chmod +x`).
- **Task falha durante `terraform validate`/`apply`**: normalmente indica
  que `add-vm-to-tfvars.sh` já validou o manifesto com sucesso, mas o
  ambiente do host de execução não tem `gcloud`/ADC configurado, ou o
  bucket de state remoto não existe. Rode
  `./scripts/create-tfstate-bucket.sh --project-id <PROJETO>` previamente.
- **`vmKey` duplicado**: o próprio `add-vm-to-tfvars.sh` valida duplicidade
  e falha com rollback; escolha uma chave diferente no formulário.
- **Campo `allowedSshCidr` obrigatório**: este campo é intencionalmente
  obrigatório no formulário para evitar liberar SSH para `0.0.0.0/0`;
  informe seu IP público com `/32` ou o CIDR da rede de administração.
- **`terraform plan`/`apply` falha com erro de tipo em `option_types` ou
  `workflow_id`/`task_ids`**: esses atributos exigem número, não string;
  os arquivos desta PoC já usam `tonumber()` nas referências — confirme que
  nenhum valor foi alterado manualmente para string.
