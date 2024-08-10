terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.59.0"
    }
  }

  backend "s3" {
    bucket = "bhavya-remote-state"
    key    = "terraform-infra-dev-DB" #we can give our key name
    region = "us-east-1"
    dynamodb_table = "bhavya-locking"
  }
}


#provide the authentication 
provider "aws" {
  region = "us-east-1"
}