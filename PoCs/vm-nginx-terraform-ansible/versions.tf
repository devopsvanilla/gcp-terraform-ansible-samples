terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  # Por padrão, nenhum backend remoto é declarado aqui.
  # Isso faz com que execuções manuais locais usem o backend "local" (terraform.tfstate).
  # Quando executado pelo Morpheus (add_vm_and_apply.sh), o backend GCS é ativado
  # dinamicamente através de um arquivo de override (backend_override.tf).

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
