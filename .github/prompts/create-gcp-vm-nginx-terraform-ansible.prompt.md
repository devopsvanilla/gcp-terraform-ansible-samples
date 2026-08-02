---
mode: "agent"
description: "Cria PoC de VM na GCP com Terraform (CPU/RAM, disco, IP externo opcional, SSH key) e configuração do Nginx com Ansible"
---

Crie uma PoC para provisionar **1 VM Linux na GCP** com Terraform e configurar **Nginx** com Ansible.

A implementação deve seguir o padrão de diretório do repositório e ser mínima, reproduzível e de baixo custo.

## Placeholders (preencha antes de executar)

- `<diretorio-da-poc>`: diretório da PoC (ex.: `PoCs/vm-nginx-custom`)
- `<nome-da-poc>`: nome lógico da PoC
- `<gcp_project_id>`: ID do projeto GCP onde a VM será criada
- `<gcp_region>`: região (ex.: `us-central1`)
- `<gcp_zone>`: zona (ex.: `us-central1-a`)
- `<vm_name>`: nome da VM
- `<machine_series>`: série da máquina (ex.: `e2`, `n2`, `n2d`)
- `<vcpu_count>`: quantidade de vCPU (ex.: `2`)
- `<memory_gb>`: memória RAM em GB (ex.: `4`)
- `<disk_type>`: tipo de disco (ex.: `pd-balanced`, `pd-ssd`, `pd-standard`)
- `<disk_size_gb>`: tamanho do disco em GB (ex.: `30`)
- `<boot_image_project>`: projeto da imagem (ex.: `debian-cloud`)
- `<boot_image_family>`: família da imagem (ex.: `debian-12`)
- `<assign_external_ip>`: `sim` ou `nao`
- `<ssh_username>`: usuário Linux para metadado SSH (ex.: `devops`)
- `<ssh_public_key>`: chave pública SSH (formato OpenSSH, ex.: `ssh-ed25519 AAAA...`)
- `<network_name>`: nome da VPC (ex.: `default`)
- `<subnetwork_name>`: nome da subnet (ou vazio se usar rede default sem subnet explícita)
- `<allowed_http_cidr>`: CIDR para HTTP/80 (ex.: `0.0.0.0/0`)
- `<allowed_ssh_cidr>`: CIDR para SSH/22 (ex.: `0.0.0.0/0` ou IP corporativo)

## Objetivo da PoC

Provisionar uma VM na GCP em `<gcp_project_id>` com:

1. seleção de CPU/RAM;
2. seleção de disco (tipo e tamanho);
3. opção de criar com ou sem IP externo;
4. injeção de chave pública SSH para acesso;
5. porta 80 liberada;
6. instalação/configuração de Nginx via Ansible.

## Requisitos obrigatórios de implementação

### Terraform

1. Criar/atualizar os arquivos conforme necessário em `<diretorio-da-poc>`:
   - `versions.tf`
   - `providers.tf`
   - `variables.tf`
   - `main.tf`
   - `outputs.tf`

2. Modelar variáveis para permitir customização de:
   - `project_id`, `region`, `zone`
   - VM: nome, série, vCPU e RAM
   - disco: tipo e tamanho
   - rede/sub-rede
   - opção de IP externo
   - usuário e chave pública SSH
   - CIDR de HTTP e SSH

3. VM com tipo customizado:
   - montar `machine_type` custom com base em `<machine_series>`, `<vcpu_count>`, `<memory_gb>`
   - exemplo esperado: `<machine_series>-custom-<vcpu_count>-<memory_mb>`

4. IP externo opcional:
   - se `<assign_external_ip> = sim`, anexar `access_config`
   - se `<assign_external_ip> = nao`, não anexar `access_config`

5. SSH key em metadados da instância:
   - formato esperado: `<ssh_username>:<ssh_public_key>`

6. Firewall:
   - regra para permitir TCP/80 a partir de `<allowed_http_cidr>`
   - regra para SSH (TCP/22) controlada por `<allowed_ssh_cidr>`
   - aplicar tags na VM para associar regras

7. Outputs mínimos:
   - nome da VM
   - IP interno
   - IP externo (quando existir)
   - comando/indicação para acessar via SSH

### Ansible (Nginx)

1. Criar estrutura Ansible dentro da PoC:
   - `ansible/site.yml`
   - `ansible/inventories/dev/hosts.yml`
   - `ansible/group_vars/`
   - `ansible/roles/nginx/tasks/main.yml`
   - `ansible/roles/nginx/handlers/main.yml`

2. O playbook deve:
   - instalar Nginx
   - garantir serviço habilitado e iniciado
   - opcionalmente publicar uma página de teste (`index.html`) simples

3. Inventário:
   - usar saída do Terraform (IP externo quando houver; caso contrário IP interno)
   - documentar pré-requisito de conectividade quando sem IP externo (VPN/bastion/IAP)

4. Idempotência:
   - tasks com `name` descritivo
   - evitar `shell`/`command` quando houver módulo nativo

## README obrigatório da PoC

Criar `README.md` em `<diretorio-da-poc>` com **exatamente** estas seções, nesta ordem:

1. O que será implantado
2. Pré-requisitos
3. Como implantar
4. Como conferir a implantação
5. Como descomissionar
6. Guia de erros comuns

Inclua:

- como preencher `terraform.tfvars` (ou equivalente)
- como aplicar Terraform
- como executar Ansible
- como validar HTTP na porta 80
- como testar SSH com a chave pública cadastrada

## Validações esperadas

- Terraform:
  - `terraform fmt`
  - `terraform validate`
  - `terraform plan`
- Ansible:
  - `ansible-lint`
  - `ansible-playbook --syntax-check`
  - `ansible-playbook --check --diff`

## Critérios de aceite

- VM criada no projeto `<gcp_project_id>` com parâmetros de compute e disco personalizados.
- Possibilidade de provisionar com e sem IP externo.
- Porta 80 acessível conforme CIDR definido.
- Chave pública SSH aplicada com sucesso.
- Nginx instalado e em execução via Ansible.
- Documentação clara e reproduzível.

## Segurança e custo

- Não hardcodar segredos.
- Manter escopo mínimo de recursos.
- Reforçar limpeza com `terraform destroy`.
