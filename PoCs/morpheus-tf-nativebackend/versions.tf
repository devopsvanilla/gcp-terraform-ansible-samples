terraform {
  required_version = ">= 1.6"

  required_providers {
    hpe = {
      source  = "HPE/hpe"
      version = ">= 1.6.0"
    }
  }
}
