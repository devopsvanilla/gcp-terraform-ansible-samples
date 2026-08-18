# HOWTO: Disparando Automações Ansible pelo Menu "Actions" da Instância (Day-2)

Este guia ensina como operadores e administradores podem acionar playbooks Ansible diretamente a partir da tela de gerenciamento de qualquer VM no Morpheus Data, além de auditar o histórico de execuções.

---

## 1. Navegando até a Instância GCP

1. Acesse o menu principal: **Provisioning > Instances**.
2. Clique no nome da VM que deseja gerenciar (ex: `vm-gcp-poc`).
3. Você entrará na página de detalhes da instância, onde verá métricas de CPU/Memória, IP, Cloud (`loonar-gcp-terraform-ansible-samples`) e status de energia.

---

## 2. Executando uma Task ou Playbook Individual

Para rodar um playbook específico imediatamente na VM selecionada:

1. No canto superior direito da página da VM, clique no botão **`ACTIONS`**.
2. No menu suspenso, selecione: **`Run Task`**.
3. No modal que abrir:
   - **TASK**: Selecione a task desejada (ex: `GCP - Instalar Pacotes e Nginx` ou `GCP - Restart VM Playbook`).
   - *(Opcional)* Preencha ou modifique variáveis em **COMMAND OPTIONS** para esta execução específica.
4. Clique em **`EXECUTE`**.

---

## 3. Executando um Workflow Operacional Completo

Para rodar uma esteira de automações encadeadas (ex: Snapshot + Restart + Validação):

1. No botão **`ACTIONS`**, selecione: **`Run Workflow`**.
2. No campo **WORKFLOW**, escolha: `GCP VM - Manutenção com Snapshot e Restart`.
3. Clique em **`EXECUTE`**.
4. O Morpheus executará todas as etapas em sequência, reportando o progresso visual de cada fase.

---

## 4. Consultando o Histórico e Auditoria da Instância

Para verificar quando, por quem e qual o resultado de cada playbook rodado naquela VM:

1. Na página de detalhes da VM, clique na aba **`History`** (no menu secundário abaixo do nome da VM).
2. Você verá a lista de todas as tarefas executadas:
   - **DATA / HORA**: Timestamp exato da execução.
   - **TIPO**: Task ou Workflow.
   - **NOME**: Nome da automação.
   - **USUÁRIO**: Quem disparou a ação (ex: `devopsvanilla`, `administrator`).
   - **STATUS**: 🟢 *Success* ou 🔴 *Failed*.
   - **DURAÇÃO**: Tempo em segundos/minutos.
3. Clique em qualquer linha do histórico para abrir a janela de detalhes e ver o **console de saída (Output)** do Ansible completo daquela execução passada.
