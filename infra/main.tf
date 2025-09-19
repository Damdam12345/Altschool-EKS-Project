terraform {
  backend "s3" {
    bucket  = "dami-project-bedrock-terraform-bucket"
    key     = "terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
  
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}