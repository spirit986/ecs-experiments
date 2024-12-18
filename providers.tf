terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.46.0"
    }
  }
  backend "s3" {
    # $md5 
    # ecs-experiments-tfstate   
    # 9099006c22730ec3d0bd7f9e134cc635
    bucket         = "ecs-experiments-tfstate-cc635-s3"
    key            = "vpc.tfstate"
    region         = "eu-north-1"
    encrypt        = "true"
    dynamodb_table = "ecs-experiments-tfstate-cc635-dynamodb"
  }
}
provider "aws" {
  region     = var.aws_region
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "ecs-experiments-tfstate-cc635-dynamodb"
  billing_mode   = "PAY_PER_REQUEST"  # or "PROVISIONED" if you want to set specific read/write capacity units
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
