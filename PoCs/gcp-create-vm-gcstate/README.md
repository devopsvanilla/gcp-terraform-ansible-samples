# PoC: Provisionamento de VMs GCP com Terraform

## O que será implantado

Esta PoC implanta **uma ou várias VMs Linux na Google Cloud Platform (GCP)** usando Terraform, com:

- tipo de máquina customizado (série + vCPU + RAM) ou predefinido (ex.: `e2-micro`);
- disco de boot customizado (tipo e tamanho);
- opção de provisionar **cada VM com ou sem IP externo**;
- chave pública SSH injetada via metadado da instância;
- regras de firewall independentes por VM para HTTP (80) e SSH (22);
- suporte a múltiplas entradas em `vms`, cada uma com configuração própria;
- um fluxo opcional para gerenciar a Org Policy `constraints/compute.vmExternalIpAccess` e liberar IP externo para as VMs do projeto, inclusive para as que forem criadas posteriormente;
- criação automática de um usuário remoto na VM via startup script, com grupos Linux opcionais definidos por VM (`user_groups`).

> 📖 **Arquitetura e Diagramas:** Para uma visão detalhada dos fluxos de provisionamento (Git → Morpheus → GCP), autenticação e credenciais, com diagramas de sequência e componentes, consulte o [`ARCHITECTURE.md`](./ARCHITECTURE.md).

## Pré-requisitos

- Linux com ferramentas instaladas:
  - `terraform` (>= 1.6)
  - `gcloud`
  - `python3` (usado pelos scripts auxiliares que editam o `terraform.tfvars`)
- Para preparar rapidamente a estação de trabalho com essas dependências, use:
  - `./scripts/install-prerequisites.sh`
  - ele verifica o ambiente, mostra no pré-flight o que será instalado e instala apenas o que estiver ausente.
- Autenticação GCP ativa via ADC ou `gcloud`:
  - `gcloud auth application-default login`
- Permissões no projeto para:
  - criar instâncias Compute Engine;
  - criar regras de firewall;
  - habilitar APIs, quando necessário;
  - alterar a Org Policy `compute.vmExternalIpAccess`, se `manage_vm_external_ip_org_policy = true`.
- Chave SSH pública no formato OpenSSH.
- Se alguma VM tiver `assign_external_ip = false`, você precisará de conectividade privada com ela (VPN, bastion ou IAP).
- Por segurança, ajuste `allowed_ssh_cidr` para **seu IP público com /32** ou para o CIDR da sua rede de administração.
- Se a política do projeto impedir o uso de IP externo, execute antes do `terraform apply`:
  - `./scripts/allow-external-ip-policy.sh --project-id poc-terraform-ansible`
  - a política é aplicada ao projeto e passa a valer para as VMs criadas nesse projeto, sem depender de uma VM já existente.
- Para aplicar todas as configurações de projeto necessárias de uma vez, use:
  - `./scripts/setup-gcp-project.sh --project-id poc-terraform-ansible`
- Para buscar elegibilidade de **free tier** da Compute Engine, prefira manter no `terraform.tfvars`:
  - `region = "us-central1"`
  - `zone = "us-central1-a"`
  - `machine_type_override = "e2-micro"`
  - `disk_type = "pd-standard"`
  - `disk_size_gb = 30`

## Como implantar

1. Acesse o diretório da PoC (`PoCs/gcp-create-vm-gcstate`).
2. Edite `terraform.tfvars` e preencha os valores reais do projeto, da zona e das chaves SSH.
3. Defina as VMs em `vms = { ... }`; cada entrada aceita `assign_external_ip = true` ou `false`.
   - Se preferir automatizar a inclusão de uma nova VM no manifesto, use o script abaixo a partir da raiz do repositório:
     - `./scripts/add-vm-to-tfvars.sh --file "./PoCs/gcp-create-vm-gcstate/terraform.tfvars" --vm-key <NOME_DA_VM> --vm-name <NOME DA VM> --machine-type-override e2-micro --machine-series e2 --vcpu-count 1 --memory-gb 1 --disk-type pd-standard --disk-size-gb 30 --boot-image-project debian-cloud --boot-image-family debian-12 --assign-external-ip true --ssh-username <USUARIO A SER CRIADO> --ssh-public-key '<SUA CHAVE>' --network-name default --subnetwork-name '' --allowed-http-cidr 0.0.0.0/0 --allowed-ssh-cidr 138.94.84.20/32 --user-group <GRUPO>`
   - O script valida os parâmetros obrigatórios, impede duplicidade de `vm_name`, executa `terraform fmt` e `terraform validate` ao final e aborta com rollback do arquivo se a inclusão deixar o manifesto inválido.
4. Se quiser que o usuário remoto seja criado automaticamente na VM e adicionado a grupos, defina `user_groups = ["sudo"]` (ou outra lista) na entrada da VM.
5. Se quiser o fluxo automático de Org Policy para IP externo, mantenha `manage_vm_external_ip_org_policy = true`.
6. Antes do primeiro `terraform init`, crie o bucket de state remoto no GCS (se for utilizar backend remoto):
   - `./scripts/create-tfstate-bucket.sh --project-id poc-terraform-ansible`
   - O bucket configurado é `gs://tfstate-devopsvanilla-samples` e o prefixo usado é `gcp-create-vm-gcstate`.
7. Execute as validações e o planejamento Terraform:
   - `terraform init`
   - `terraform fmt`
   - `terraform validate`
   - `terraform plan`
8. Aplique a infraestrutura:
   - `terraform apply`

## Como conferir a implantação

- Confirmar outputs Terraform:
  - `terraform output vm_names`
  - `terraform output vm_internal_ips`
  - `terraform output vm_external_ips`
  - `terraform output vm_details`
  - `terraform output deployment_summary`
- Testar SSH com a chave correspondente à pública cadastrada em cada VM:
  - `ssh -i <caminho-da-chave-privada> <ssh_username>@<ip-da-vm>`
- Conferir o usuário remoto criado pela inicialização da VM e os grupos atribuídos:
  - `gcloud compute ssh --zone=<zona> --project=<project_id> <ssh_username>@<vm_name> --command='id <ssh_username> && groups <ssh_username>'`
- Validar conectividade de rede com a VM:
  - `ping -c 3 <ip-da-vm>` (se ICMP liberado) ou testar porta SSH: `nc -zv <ip-da-vm> 22`

## Como descomissionar

- No diretório da PoC:
  - `terraform destroy`
- Se quiser remover apenas uma VM do manifesto antes de rodar `terraform plan`/`terraform apply`, use a partir da raiz do repositório:
  - `./scripts/remove-vm-from-tfvars.sh --file "./PoCs/gcp-create-vm-gcstate/terraform.tfvars" --name <NOME DA VM>`
- O script de remoção localiza o bloco com `vm_name` igual ao valor informado, remove o bloco completo, executa `terraform fmt` e `terraform validate` e restaura o arquivo original se a remoção deixar o manifesto inválido.
- Para limpar o state remoto no GCS ou excluir o bucket após o destroy:
  - `./scripts/cleanup-tfstate-bucket.sh --project-id poc-terraform-ansible`
- Confirmar no Console GCP que VM, regras de firewall e políticas da PoC foram removidas.

## Guia de erros comuns

- **Erro de autenticação no Terraform (403/401):** verifique login, ADC e permissões no projeto.
- **`SERVICE_DISABLED` / `Compute Engine API has not been used...`:** a POC tenta habilitar `compute.googleapis.com` automaticamente. Se ainda falhar, sua identidade provavelmente não tem permissão para ativar APIs no projeto; nesse caso, habilite a API no Console GCP ou com `gcloud services enable compute.googleapis.com --project <project_id>`, aguarde a propagação e rode `terraform apply` novamente.
- **`orgpolicy.googleapis.com` / quota project:** se o Terraform falhar com erro de quota project, certifique-se de que a conta ADC esteja autenticada e de que o projeto esteja correto. A automação tenta configurar isso automaticamente quando necessário.
- **Erro `Constraint constraints/compute.vmExternalIpAccess violated`:** a PoC tenta aplicar a regra no nível do projeto para VMs com `assign_external_ip = true`. Se o erro persistir, provavelmente há política herdada de Folder/Org sem possibilidade de override; nesse caso, peça liberação no nível superior ou desative a gestão automática com `manage_vm_external_ip_org_policy = false`.
- **`network` ou `subnetwork` não encontrados:** revise `network_name` e `subnetwork_name` no `terraform.tfvars`.
- **Falha ao usar `add-vm-to-tfvars.sh`:** confirme se `python3` e `terraform` estão instalados, se `--vm-key` é único e se `--vm-name` ainda não existe no `terraform.tfvars`.
- **Falha ao usar `remove-vm-from-tfvars.sh`:** confirme se o valor passado em `--name` corresponde exatamente ao atributo `vm_name` do bloco que você quer remover.
- **Sem acesso SSH com `assign_external_ip = false`:** use conectividade privada (VPN, bastion ou IAP).
- **SSH não conecta mesmo com IP externo:** confira se `allowed_ssh_cidr` contém o seu IP público atual com `/32` e se ele não mudou desde o `terraform apply`.
- **`Permission denied (publickey)`:** confirme se a chave privada corresponde à pública em `ssh_public_key` e se o usuário usado em `ssh_username` existe na VM.
- **Usuário remoto não entra nos grupos esperados:** revise `user_groups` no `terraform.tfvars` e confirme a criação do usuário via startup script.
