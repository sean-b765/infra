# Rest API backend for the node.js/express backend container image

# ECR registry for the container image
resource "aws_ecr_repository" "productlookup_ecr" {
  name                 = "productlookup-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

# # Lambda fn based on container image
# resource "aws_lambda_function" "productlookup_lambda_fn" {
#   function_name    = "productlookup"
#   role             = aws_iam_role.lambda_exec_role.arn
#   memory_size      = 512
#   timeout          = 10
#   package_type = "Image"
#   image_uri = "${aws_ecr_repository.productlookup_ecr.repository_url}:latest"

#   lifecycle {
#     ignore_changes = [
#       image_uri
#     ]
#   }
# }

# # REST API
# resource "aws_api_gateway_rest_api" "productlookup_api" {
#   name = "productlookup-api"
# }

# # Create a Proxy Resource
# resource "aws_api_gateway_resource" "proxy" {
#   rest_api_id = aws_api_gateway_rest_api.productlookup_api.id
#   parent_id   = aws_api_gateway_rest_api.productlookup_api.root_resource_id
#   path_part   = "{proxy+}"
# }

# resource "aws_api_gateway_method" "proxy_method" {
#   rest_api_id   = aws_api_gateway_rest_api.productlookup_api.id
#   resource_id   = aws_api_gateway_resource.proxy.id
#   http_method   = "ANY"
#   authorization = "NONE"
# }

# # Lambda integration
# resource "aws_api_gateway_integration" "lambda_integration" {
#   rest_api_id             = aws_api_gateway_rest_api.productlookup_api.id
#   resource_id             = aws_api_gateway_resource.proxy.id
#   http_method             = aws_api_gateway_method.proxy_method.http_method
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.productlookup_lambda_fn.invoke_arn
# }

# # Deployment / Prod stage
# resource "aws_api_gateway_deployment" "api_deploy" {
#   depends_on  = [aws_api_gateway_integration.lambda_integration]
#   rest_api_id = aws_api_gateway_rest_api.productlookup_api.id
# }

# resource "aws_api_gateway_stage" "prod" {
#   deployment_id = aws_api_gateway_deployment.api_deploy.id
#   rest_api_id   = aws_api_gateway_rest_api.productlookup_api.id
#   stage_name    = "prod"
# }

# # Usage Plan
# resource "aws_api_gateway_usage_plan" "bill_protector" {
#   name = "strict-budget-plan"

#   api_stages {
#     api_id = aws_api_gateway_rest_api.productlookup_api.id
#     stage  = aws_api_gateway_stage.prod.stage_name
#   }

#   # Throttling: How many requests PER SECOND
#   throttle_settings {
#     burst_limit = 50
#     rate_limit  = 10
#   }

#   # Quota: Maximum requests PER Period
#   quota_settings {
#     limit  = 5000
#     period = "MONTH"
#   }
# }