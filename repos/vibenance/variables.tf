variable "s3_name" {
  description = "Name of S3 bucket"
  type        = string
  default     = "seanboadendev-vibenance"
}
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}
variable "gh_repo" {
  description = "GitHub repo, like 'org_name/repo_name'"
  type        = string
}
