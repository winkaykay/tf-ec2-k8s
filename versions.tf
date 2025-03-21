terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.89.0"
    }
  }
}

#provider "aws" {
  # Configuration options
  #profile = "master-programmatic-admin"
  #region  = var.region
  #access_key = var.access_key
  #secret_key = var.secret_key
#}