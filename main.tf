resource "aws_budgets_budget" "main_budget" {
  name         = "main-monthly-budget"
  budget_type  = "COST"
  limit_amount = "10.0"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
}

# Certificate

data "aws_acm_certificate" "public" {
  domain   = "seanboaden.dev"
  statuses = ["ISSUED"]
  provider = aws.us_east_1
}

# vibenance module
module "vibenance" {
  source                 = "./repos/vibenance"
  aws_region             = var.aws_region
  gh_repo                = "sean-b765/vibenance"
  viewer_certificate_arn = data.aws_acm_certificate.public.arn
}

module "seanboadendotdev" {
  source                 = "./repos/seanboadendotdev"
  project_name           = "seanboadendotdev"
  aws_region             = var.aws_region
  gh_repo                = "sean-b765/seanboadendotdev"
  viewer_certificate_arn = data.aws_acm_certificate.public.arn
}
