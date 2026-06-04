terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.92"
    }
  }

  required_version = ">= 1.2"

  backend "s3" {
    bucket       = "seanboaden-dev-tfstate"
    key          = "terraform.tfstate"
    region       = "ap-southeast-2"
    profile      = "default"
    use_lockfile = true
    encrypt      = true
  }
}
