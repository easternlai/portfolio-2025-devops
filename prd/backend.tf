terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.98.0"
    }
  }

  backend "s3" {
    bucket         = "easternlai-terraform-backend"
    key            = "backend.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "tf-backend"
    profile        = "portfolio-prd"
  }
}

provider "aws" {
  region  = var.region
  profile = "portfolio-prd"
}
