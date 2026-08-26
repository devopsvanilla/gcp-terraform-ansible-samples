# GCP + Terraform + Ansible + Morpheus Data — Proof of Concept Hub

Repositório unificado de **Provas de Conceito (PoCs)**, modelos arquiteturais e automações para **Google Cloud Platform (GCP)**, integrando **Terraform (IaC)**, **Ansible (Configuration Management & Day-2 Ops)** e a plataforma multicloud **Morpheus Data CMP**.

O objetivo deste repositório é fornecer padrões de automação reproduzíveis, seguros e de baixo custo, cobrindo desde o provisionamento de infraestrutura básica até a governança avançada de ciclo de vida e catálogos de autosserviço.

---

## 🏛️ Estrutura do Repositório

```
gcp-terraform-ansible-samples/
├── PoCs/
│   ├── gcp-create-vm/                 # 1. Provisionamento básico de VM no GCP com Terraform puro
│   ├── morpheus-tf-nativestate/       # 2. App Blueprint Morpheus com estado nativo no Cypher
│   ├── morpheus-tf-remotestate/       # 3. Morpheus Data com Remote State no Google Cloud Storage (GCS)
│   ├── gcp-create-vm-gcstate/         # 4. Provisionamento avançado de VMs no GCP com Terraform (GCS State)
│   └── ansible/                       # 5. Gerenciamento Morpheus & VMs GCP via coleção Ansible morpheus.core
├── scripts/                           # Utilitários de apoio (setup GCP, codificação de chaves, hooks)
└── .github/                           # Convenções e instruções do repositório
```

---

## 📋 Catálogo de Provas de Conceito (PoCs)

| PoC | Foco Tecnológico | Descrição |
|---|---|---|
| 🚀 [`PoCs/gcp-create-vm`](PoCs/gcp-create-vm/README.md) | **Terraform Puro + GCP** | Provisionamento enxuto de instância Compute Engine (Debian/Ubuntu) no GCP com regras de firewall e IP público. |
| 🎛️ [`PoCs/morpheus-tf-nativestate`](PoCs/morpheus-tf-nativestate/README.md) | **Morpheus Data + Terraform + Cypher** | App Blueprint nativo do Morpheus consumindo código Terraform com estado (`tfstate`) e variáveis mantidos no cofre Cypher. |
| 🗄️ [`PoCs/morpheus-tf-remotestate`](PoCs/morpheus-tf-remotestate/README.md) | **Morpheus Data + GCS Backend** | Automação Morpheus com backend remoto no Google Cloud Storage (GCS) e estado isolado por instância de VM. |
| 🌐 [`PoCs/gcp-create-vm-gcstate`](PoCs/gcp-create-vm-gcstate/README.md) | **Terraform Multi-VM + GCP** | PoC de provisionamento de instâncias Compute Engine com suporte a múltiplas VMs, startup script, SSH customizado e Org Policy. |
| ⚡ [`PoCs/ansible`](PoCs/ansible/README.md) | **Ansible Collection `morpheus.core`** | Orquestração da API do Morpheus para gerenciar VMs GCP (Start/Stop, Snapshots, Cypher, Inventário Dinâmico e Day-2 Ops). |

---

## 📚 Guias Práticos e Documentações Detalhadas

### ☁️ Conexão e Gestão de Estado no Morpheus/GCP
- 📖 [Guia de Autenticação e Conexão gcloud CLI](PoCs/morpheus-tf-nativestate/HOWTO-gcloud-connect.md): Passo a passo para autenticar no GCP e configurar chaves de Service Account.
- 📖 [Guia de Resolução de Drift e Sincronização de Estado](PoCs/morpheus-tf-nativestate/HOWTO-tfstate-drift.md): Procedimentos para lidar com drift de estado no Cypher/Terraform.

### 🎛️ Automação Visual e Day-2 no Morpheus Data
- 📖 [HOWTO: Criar e Executar Ansible Tasks na UI](PoCs/ansible/HOWTO-ansible-tasks-ui.md): Configuração de tarefas Ansible Playbook integradas ao Git no Morpheus.
- 📖 [HOWTO: Workflows e Ciclo de Vida (Provisioning & Day-2)](PoCs/ansible/HOWTO-workflows-lifecycle.md): Encadeamento de fases (Post-Provision, Teardown e Operacional).
- 📖 [HOWTO: Disparando Automações pelo Menu Actions da Instância](PoCs/ansible/HOWTO-instance-actions-day2.md): Execução direta e auditoria na aba History de qualquer VM.
- 📖 [HOWTO: Publicar Playbooks no Catálogo Self-Service](PoCs/ansible/HOWTO-service-catalog-forms.md): Criação de formulários com Option Types/Inputs para usuários finais.

---

## 🛠️ Pré-requisitos Gerais

| Ferramenta | Versão Mínima | Finalidade |
|---|---|---|
| `terraform` | `>= 1.6.0` | Provisionar infraestrutura no GCP e configurar recursos no Morpheus |
| `ansible-core` | `>= 2.11` | Executar playbooks locais, inventário dinâmico e coleção `morpheus.core` |
| `python3` / `pip` | `>= 3.10` | Execução de dependências (`requests`, `packaging`) |
| `gcloud` CLI | Última estável | Gerenciamento de projetos, APIs, IAM e políticas da organização |
| `git` | Qualquer | Controle de versão |

> [!NOTE]
> O runner nativo de blueprints Terraform do Morpheus Data **não possui** `gcloud` nem `ansible-playbook` instalados dentro do seu container de execução. Portanto, o código do Blueprint deve utilizar APIs nativas do provider Terraform, enquanto playbooks Ansible operam via **Ansible Tasks/Workflows** ou externamente via transporte **HTTPAPI**.

---

## 🔒 Boas Práticas e Segurança

- **Credenciais**: Nunca faça commit de arquivos `.tfstate`, `terraform.tfvars`, arquivos `*.key.json` ou senhas em texto puro.
- **Ansible Vault**: Utilize `ansible-vault encrypt` para proteger arquivos sensíveis como `group_vars/morpheus.yml`.
- **Morpheus Cypher**: Centralize segredos, certificados e arquivos `tfvars` no cofre Cypher do Morpheus (`secret/`, `tfvars/`).
- **Descomissionamento**: Execute `terraform destroy` ou remova instâncias no Morpheus ao concluir testes para otimizar custos no GCP.
