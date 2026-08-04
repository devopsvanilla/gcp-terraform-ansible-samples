terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  backend "gcs" {
    bucket = "tfstate-devopsvanilla-samples"
    prefix = "vm-nginx-terraform-ansible"
  }

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
