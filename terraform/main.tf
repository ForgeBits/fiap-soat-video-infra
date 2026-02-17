terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # Trava na versão 5.x
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "random_id" "id" {
  byte_length = 4
}

variable "db_password" {
  description = "Senha master para RDS e Brokers"
  default     = "7cl2MsI90x9VkqEzZgYc"
}