# HOWTO: Transformando Playbooks Ansible em Itens do Catálogo Self-Service com Formulários

Este guia ensina como publicar automações Ansible no **Catálogo de Serviços (Self-Service)** do Morpheus Data, permitindo que desenvolvedores e operadores executem tarefas através de formulários visuais simples e controlados, sem precisar acessar o terminal ou editar código.

---

## 1. Conceito do Catálogo Self-Service no Morpheus

```
[ Usuário no Portal Self-Service ]
               │
               ▼ Preenche formulário visual (ex: Escolhe VM e Ação)
[ Item do Catálogo (Catalog Item) ]
               │
               ▼ Injeta inputs como `--extra-vars`
[ Ansible Task / Workflow ]
               │
               ▼ Executa playbook
[ Instância no GCP ]
```

---

## 2. Passo 1: Criar os Campos do Formulário (Option Types / Inputs)

Se você deseja que o usuário informe parâmetros (ex: escolher se quer instalar Nginx ou qual o estado da VM):

1. Navegue até: **Library > Options > Option Types** (ou **Inputs** dependendo da versão).
2. Clique em **`+ ADD`**.
3. Crie os campos necessários:

### Exemplo de Campo: `Instalar Nginx (Checkbox)`
- **NAME**: `Instalar Nginx`
- **FIELD NAME**: `enable_nginx_example` *(deve ser igual ao nome da variável no playbook Ansible)*
- **TYPE**: `Checkbox`
- **DEFAULT VALUE**: `false`
- **HELP BLOCK**: `Marque para instalar e habilitar o servidor Nginx na VM.`

### Exemplo de Campo: `Ação Operacional (Select Dropdown)`
- **NAME**: `Ação na VM`
- **FIELD NAME**: `target_state` *(variável usada no playbook `04-manage-instance.yml`)*
- **TYPE**: `Select List`
- **OPTION LIST**: Crie uma lista manual com os valores: `started`, `stopped`, `restarted`, `backup`.

---

## 3. Passo 2: Criar o Item no Catálogo de Serviços

1. Acesse: **Library > Service Catalog > Catalog Items** (ou **Library > Automation > Catalog Items**).
2. Clique no botão **`+ ADD`**.
3. Selecione o tipo de item: **`Workflow`** ou **`Operational Task`**.

### Configuração do Item:

| Campo | Valor Exemplo | Descrição |
|---|---|---|
| **NAME** | `Solicitar Manutenção em VM GCP` | Nome exibido no catálogo |
| **DESCRIPTION** | `Executa snapshot preventivo e reinicialização controlada na VM selecionada.` | Descrição para o usuário |
| **CATEGORY** | `Operações Day-2` | Categoria de agrupamento no portal |
| **ICON** | Selecione um ícone amigável (ex: ícone do GCP ou Ansible) | Identidade visual |
| **WORKFLOW / TASK** | `GCP VM - Manutenção com Snapshot e Restart` | Automação que será disparada |
| **INPUTS / OPTION TYPES** | Adicione os campos criados no Passo 1 | Formulário exibido ao usuário |
| **VISIBILITY** | `Public` ou vinculado a tenants/roles específicos | Controle de acesso RBAC |

4. Clique em **`SAVE CHANGES`**.

---

## 4. Passo 3: Como o Usuário Final Utiliza o Catálogo

1. O usuário final (desenvolvedor/operador) acessa o menu: **Service Catalog** (ou **Self Service**).
2. Localiza o card: **`Solicitar Manutenção em VM GCP`**.
3. Clica em **`ORDER`** (Solicitar).
4. Um formulário visual é exibido com os campos que você configurou (ex: seleção da VM, opções de manutenção).
5. O usuário clica em **`SUBMIT`**.
6. O Morpheus:
   - Valida eventuais políticas de aprovação (se houver política financeira/técnica configurada).
   - Injeta os dados preenchidos no formulário como variáveis no Ansible.
   - Dispara a execução e exibe uma barra de progresso visual para o usuário.
