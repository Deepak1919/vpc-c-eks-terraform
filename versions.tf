terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 7.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }

  # Supply all actual S3 settings from backend.hcl during `terraform init`.
  # Do not put credentials or a bucket name in this source file.
  backend "s3" {}
}
