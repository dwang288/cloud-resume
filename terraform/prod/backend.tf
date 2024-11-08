terraform {

  backend "s3" {
    bucket         = "duan-production-tf-state-us-east-2"
    key            = "terraform/states/prod/terraform.tfstate"
    dynamodb_table = "terraform-state-lock"
    region         = "us-east-2"
    encrypt        = "true"
  }
}