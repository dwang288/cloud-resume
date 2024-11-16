terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.74.0"
    }
  }

  backend "s3" {
    bucket         = "duan-production-tf-state-us-east-2"
    key            = "terraform/states/prod/terraform.tfstate"
    dynamodb_table = "terraform-state-lock"
    region         = "us-east-2"
    encrypt        = "true"
  }
}
