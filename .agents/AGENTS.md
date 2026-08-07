# AGENTS.md — Diretrizes Gerais para Agentes de IA

Este documento reúne o conjunto consolidado de regras e padrões do repositório para orientação de Agentes de IA e ferramentas de assistência de código (como GitHub Copilot e Antigravity).

---

## 1. Propósito e Escopo do Repositório

- O repositório é dedicado a **Provas de Conceito (POCs) em Terraform para Google Cloud Platform (GCP) e Morpheus Data (via provedor `HPE/hpe`)** com suporte opcional a **Ansible** para configuração/bootstrap de ativos e scripts auxiliares em **Bash Linux**.
- As POCs devem focar em unidades mínimas e verificáveis de infraestrutura e automação, com **baixo custo**, **facilidade de reprodução** e **descomissionamento limpo (`terraform destroy`)**.
- Padrão obrigatório de caminho para POCs: `PoCs/<nome-da-poc>/` (atenção às maiúsculas no prefixo `PoCs/`).
- **Idioma Obrigatório**: Toda a documentação do repositório deve ser escrita obrigatoriamente em **Português do Brasil (pt-BR)**.
- **Linter de Markdown**: Todo documento `.md` criado ou alterado deve obrigatoriamente passar por validação com **markdown lint** (`markdownlint` ou `pymarkdown scan`).

---

## 2. Fluxo de Trabalho Recomendado em 3 Fases

Ao criar, evoluir ou refatorar qualquer POC neste repositório, o agente deve seguir este ciclo de 3 fases:

### Fase 1 — Diagnóstico
1. Inspecionar o diretório `PoCs/<nome-da-poc>/` se existente ou planejar a nova POC.
2. Identificar lacunas em relação à estrutura padrão:
   - Terraform (`versions.tf`, `providers.tf`, `main.tf`, `variables.tf`, `outputs.tf`).
   - `README.md` da POC com as 6 seções obrigatórias.
   - Estrutura de Ansible em `PoCs/<nome-da-poc>/ansible/` (se aplicável).
   - Scripts em `PoCs/<nome-da-poc>/scripts/` ou `helpers/` (se aplicável).
3. Propor um plano de implementação curto, incremental e testável.

### Fase 2 — Implementação
1. Escrever o código Terraform, Ansible, Bash ou Documentação respeitando os padrões de linguagem.
2. Garantir idempotência e segurança (nenhuma credencial ou segredo hardcoded).
3. Atualizar o `README.md` principal na raiz do repositório adicionando a nova POC ao índice.

### Fase 3 — Validação e Fechamento
1. Executar os Quality Gates correspondentes (fmt, validate, lint, shellcheck).
2. Reportar ao usuário o resumo das alterações, instruções reproduzíveis de execução e comandos de descomissionamento.

---

## 3. Padrões por Tecnologia

### Terraform (GCP & HPE Morpheus Data)
- **Estrutura de arquivos**: Separe por intenção em POCs (`versions.tf`, `providers.tf`, `main.tf`, `variables.tf`, `outputs.tf`).
- **Provedor HPE Morpheus**: Declarar `HPE/hpe` em `versions.tf` (`source = "HPE/hpe"`).
- **Nomenclatura**: Use `snake_case` para recursos, módulos e variáveis. Não repita o tipo do recurso no nome lógico (ex.: use `resource "google_compute_instance" "main"` em vez de `main_instance`).
- **Variáveis**: Toda variável deve possuir `type` e `description`. Marcar `sensitive = true` em tokens/chaves.
- **Outputs**: Todo output deve possuir `description` explicativa.
- **GCP**: Explicite `project_id`, `region` e `zone`. Documente APIs/serviços GCP necessários.
- **Segurança**: Nunca hardcodar senhas/chaves/tokens. Não commitar arquivos de estado local (`terraform.tfstate*`) ou `.terraform/`.
- **Quality Gate**: `terraform fmt`, `terraform validate`, `terraform plan`.

### Ansible
- **Estrutura**: Ao utilizar Ansible em uma POC, organize em `PoCs/<nome-da-poc>/ansible/` com `site.yml`, `inventories/`, `group_vars/`, `host_vars/` e `roles/`.
- **Tasks**: Toda task deve ter um atributo `name` descritivo.
- **Módulos**: Priorize módulos nativos do Ansible. Evite `shell`/`command` a menos que estritamente necessário (e com justificativa).
- **Idempotência**: Garanta que as playbooks possam rodar N vezes produzindo o mesmo resultado final. Use handlers para reinícios de serviço.
- **Quality Gate**: `ansible-lint`, `ansible-playbook --syntax-check`, `ansible-playbook --check --diff`.

### Bash Linux
- **Shebang & Flags**: Inicie todo script com `#!/usr/bin/env bash` e habilite o modo estrito: `set -euo pipefail`.
- **Boas práticas**:
  - Faça quoting seguro de variáveis: `"${var}"`.
  - Use `[[ ... ]]` para condicionais em vez de `[ ... ]`.
  - Estruture scripts longos com funções pequenas e uma função `main "$@"`.
- **Interface**: Suporte à flag `--help`, validação de parâmetros de entrada e verificação prévia de dependências executáveis (`terraform`, `gcloud`, etc.).
- **Logs**: Envie mensagens de erro para STDERR usando prefixos padronizados (`[INFO]`, `[WARN]`, `[ERROR]`).
- **Quality Gate**: `shellcheck`.

### Documentação (READMEs e Manuais)
- **Idioma Obrigatório**: Toda a documentação deve ser redigida exclusivamente em **Português do Brasil (pt-BR)**.
- **Quality Gate**: Executar obrigatoriamente `pymarkdown scan` ou `markdownlint` em qualquer arquivo `.md` criado ou alterado.

- **README Raiz (`/README.md`)**:
  1. Propósito do repositório.
  2. Organização e estrutura de pastas.
  3. Índice atualizado com links para cada POC em `PoCs/<nome-da-poc>/`.
  4. Pré-requisitos gerais e considerações de segurança/custos.

- **README da POC (`PoCs/<nome-da-poc>/README.md`)**:
  Deve ter **exatamente** as seguintes 6 seções na ordem correta:
  1. `O que será implantado`
  2. `Pré-requisitos`
  3. `Como implantar`
  4. `Como conferir a implantação`
  5. `Como descomissionar`
  6. `Guia de erros comuns`

---

## 4. Referências Oficiais da Solução HPE Morpheus Data

Sempre que atuar ou consultar informações sobre o Morpheus Data, o agente deve obter diretrizes da documentação oficial da HPE:

- **Provedor Terraform HPE**: <https://registry.terraform.io/providers/HPE/hpe/latest>
- **Configurações da solução e uso da console web**: <https://support.hpe.com/hpesc/public/docDisplay?docId=sd00008014en_us&page=GUID-709AAADB-A9C1-40B6-AD22-958EE7E6F312.html>
- **API e CLI Morpheus Data**: <https://support.hpe.com/hpesc/public/docDisplay?docId=sd00008014en_us&page=GUID-F695DE83-0DF8-4C5E-A932-79B60E12C7B4.html>
- **Repositórios no GitHub (HPE)**: <https://github.com/HewlettPackard/?q=morpheus&type=all&language=&sort=>
- **Whitepapers e Relatórios**: <https://www.hpe.com/us/en/resource-library.html/search/morpheus?type=whitepapers-and-reports>

---

## 5. Skills Disponíveis no Repositório

As automações e verificações do agente são apoiadas pelas seguintes skills personalizadas localizadas em `.agents/skills/`:

1. `poc-scaffold`: Guia completo de scaffold para novas POCs GCP e HPE Morpheus.
2. `poc-readme-validator`: Verificação das 6 seções obrigatórias no README de POC.
3. `terraform-quality-gate`: Validação de código Terraform na GCP e HPE Morpheus.
4. `ansible-quality-gate`: Validação de playbooks e inventários Ansible.
5. `bash-quality-gate`: Validação de scripts Bash Linux.
