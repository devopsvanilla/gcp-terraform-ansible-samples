# HOWTO: Criação e Execução de Ansible Tasks na UI do Morpheus Data

Este guia ensina passo a passo como configurar e executar tarefas do tipo **Ansible Playbook** utilizando a interface web do Morpheus Data, aproveitando os playbooks deste repositório Git.

---

## 1. Pré-requisito: Integração com o Repositório Git

Antes de criar a Task, certifique-se de que o repositório Git já está adicionado no Morpheus:

1. Acesse no menu: **Administration > Integrations**.
2. Verifique se existe a integração do tipo **Git** (ex: ID `15` / Repo ID `63`).
3. Certifique-se de que a branch padrão configurada é `main` (ou a branch de trabalho).

---

## 2. Criando uma Ansible Task na Interface Web

1. Navegue até: **Provisioning > Automation > Tasks**.
2. Clique no botão **`+ ADD`** no canto superior direito.
3. No modal de seleção de tipo, escolha **`Ansible Playbook`**.

### Campos do Formulário:

| Campo | Valor Recomendado / Exemplo | Descrição |
|---|---|---|
| **NAME** | `GCP - Restart VM Playbook` | Nome amigável da tarefa |
| **CODE** | `gcp-restart-vm-task` | Identificador único interno |
| **REPOSITORY** | `gcp-terraform-ansible-samples` | Selecione seu repositório Git |
| **GIT REF** | `main` | Branch ou tag Git |
| **PLAYBOOK** | `PoCs/ansible/playbooks/04-manage-instance.yml` | Caminho relativo do playbook no repositório |
| **COMMAND OPTIONS** | `-e "target_instance_name=vm-gcp-poc target_state=restarted"` | Variáveis extras passadas ao Ansible |
| **EXECUTE TARGET** | `Local` *(para chamadas na API Morpheus)* ou `Specified Host` | Onde o binário do Ansible roda |
| **RETRYABLE** | `Marcado` (Opcional) | Permite retentar em caso de falha |

4. Clique em **`SAVE CHANGES`**.

---

## 3. Exemplos Práticos de Configuração de Tasks

### Exemplo A: Task de Snapshot Preventivo
- **Name**: `GCP - Criar Snapshot de VM`
- **Playbook**: `PoCs/ansible/playbooks/05-instance-snapshot.yml`
- **Command Options**: `-e "target_instance_name=vm-gcp-poc snapshot_action=present snapshot_name=Pre-Manutencao"`
- **Execute Target**: `Local`

### Exemplo B: Task de Configuração de SO / Nginx
- **Name**: `GCP - Instalar Pacotes e Nginx`
- **Playbook**: `PoCs/ansible/playbooks/09-configure-with-inventory.yml`
- **Command Options**: `-e "ansible_user=devopsvanilla enable_nginx_example=true"`
- **Execute Target**: `Morpheus Agent` ou `Remote` (SSH)

---

## 4. Executando a Task Manualmente

1. Na lista de **Tasks** (**Provisioning > Automation > Tasks**):
2. Localize a task desejada (ex: `GCP - Restart VM Playbook`).
3. Clique no menu de ações laterais (ícone `...` ou botão de engrenagem) e selecione **`Execute`**.
4. Se o Execute Target for configurado para receber um host específico, selecione a instância `vm-gcp-poc`.
5. Clique em **`EXECUTE`**.

---

## 5. Visualizando os Logs em Tempo Real

1. Navegue até: **Operations > Activity > Executions**.
2. Clique no job correspondente à sua execução recente.
3. Na aba **Output**, você verá o console colorido do Ansible com o streaming ao vivo do *stdout* e *stderr*.
4. O status mudará visualmente para:
   - 🟢 **Success** (Verde): Playbook executado com sucesso.
   - 🔴 **Failed** (Vermelho): Exibirá a stack trace exata da falha para diagnóstico rápido.
