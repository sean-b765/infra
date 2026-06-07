provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

provider "aws" {
  region = "us-east-1"
  alias  = "us_east_1"
}
