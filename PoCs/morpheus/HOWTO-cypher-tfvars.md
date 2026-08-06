# Como Usar o Módulo `tfvars` do Cypher no Morpheus Data

Este guia explica o funcionamento, a configuração e a utilização do mountpoint **`tfvars`** no **Cypher do Morpheus Data** para armazenamento seguro e injeção de variáveis do Terraform.

---

## 1. O que é o Módulo `tfvars` no Cypher?

O **Cypher** é o cofre seguro de chaves/valores (secret store) integrado nativamente ao Morpheus Data. Ele suporta diversos *mountpoints* (pontos de montagem como `secret`, `password`, `uuid`, `vault`, etc.), sendo o **`tfvars`** um módulo especializado para armazenar o conteúdo completo de arquivos de variáveis do Terraform (`.tfvars`).

### Principais Benefícios:
* **Segurança:** Evita o armazenamento de credenciais, chaves ou senhas em texto claro em repositórios Git ou em Blueprints.
* **Injeção Dinâmica:** O Morpheus lê a chave no Cypher e injeta automaticamente as variáveis durante as fases de `plan` e `apply` do Terraform.
* **Centralização:** Permite reutilizar conjuntos de variáveis entre diferentes Blueprints e instâncias do Morpheus.

---

## 2. Passo a Passo de Configuração no Morpheus

### Passo 1: Criar a chave no Cypher
1. Na interface do Morpheus, navegue até **Ferramentas (Tools) > Cypher**.
2. Clique no botão **+ Adicionar (+ Add)**.
3. Preencha os campos conforme a tabela abaixo:

| Campo | Descrição | Exemplo de Preenchimento |
| :--- | :--- | :--- |
| **Chave (Key)** | Nome do segredo prefixado obrigatoriamente por `tfvars/` | `tfvars/gcp-app-hml` |
| **Valor (Value)** | Conteúdo completo do arquivo em sintaxe HCL ou JSON | *(Ver exemplo abaixo)* |
| **Concessão (Lease / TTL)** | Tempo de expiração em segundos (`0` para ilimitado) | `0` |

#### Exemplo de conteúdo para o campo **Valor**:
```hcl
project_id   = "my-gcp-project-12345"
region       = "us-central1"
environment  = "staging"
db_password  = "S3cur3P@ssw0rd!2026"
allowed_cidrs = ["10.0.0.0/16", "192.168.1.0/24"]
enable_ha    = true
```

4. Clique em **Salvar (Save)**.

---

## 3. Como Utilizar o `tfvars` em Provisonamentos e Blueprints

### Opção A: Vinculação direta em Terraform App Blueprints
Ao criar ou editar um App Blueprint do tipo **Terraform** no Morpheus:
1. No formulário do Blueprint, localize o campo **TFVAR Secret** (ou *TFVar Cypher Secret*).
2. Selecione a chave criada no Cypher (ex.: `tfvars/gcp-app-hml`).
3. Quando o Morpheus executar a implantação, ele buscará esse segredo no Cypher, criará um arquivo `.tfvars` temporário no ambiente de execução e o passará via argumento `-var-file`.

### Opção B: Interpolação via Morpheus Expression Engine
Você também pode ler a chave dinamicamente em Tasks, Scripts ou Templates do Morpheus utilizando a expressão do Cypher:

```hcl
<%=cypher.read('tfvars/gcp-app-hml')%>
```

---

## 4. Boas Práticas de Segurança

1. **Separação por Ambientes:** Crie chaves distintas no Cypher para cada ambiente (ex.: `tfvars/app-dev`, `tfvars/app-hml`, `tfvars/app-prd`).
2. **Controle de Acesso (RBAC):** Restrinja as permissões de leitura/escrita dos segredos no Cypher com base nas Roles e Tenancy do Morpheus.
3. **Validade de Segredos:** Para credenciais temporárias ou testes, utilize um tempo de concessão (TTL) diferente de zero.

---

## 5. Referências

* [Morpheus Data Documentation - Cypher Secret Management](https://docs.morpheusdata.com/en/latest/tools/cypher/cypher.html)
* [Morpheus Data Documentation - Terraform Integration & Blueprints](https://docs.morpheusdata.com/en/latest/provisioning/apps/type_spec/terraform.html)
* [HPE Morpheus Terraform Provider Documentation](https://registry.terraform.io/providers/HPE/hpe/latest/docs)
