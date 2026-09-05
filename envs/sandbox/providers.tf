terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Bypass AWS Academy SCP restrictions for S3 Object Lock & metadata API calls
  s3_use_path_style           = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
}