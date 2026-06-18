output "vibenance_github_actions_role_arn" {
  description = "OpenID Connect role to assume in github actions"
  value       = module.vibenance.github_actions_role_arn
}

output "seanboadendotdev_github_actions_role_arn" {
  description = "OpenID Connect role to assume in github actions"
  value       = module.seanboadendotdev.github_actions_role_arn
}
