resource "aws_budgets_budget" "main_budget" {
  name         = "main-monthly-budget"
  budget_type  = "COST"
  limit_amount = "10.0"
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
}
