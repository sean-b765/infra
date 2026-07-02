# Static files pushed to S3 and cached on CloudFront
locals {
  s3_origin_id   = "${var.s3_name}-origin"
  s3_domain_name = "${var.s3_name}.s3-website-${var.aws_region}.amazonaws.com"
}

resource "aws_s3_bucket" "this" {
  bucket = var.s3_name
}

data "aws_iam_policy_document" "origin_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontServiceRead"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.this.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.bucket
  policy = data.aws_iam_policy_document.origin_bucket_policy.json
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.project_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Security header policy

resource "aws_cloudfront_response_headers_policy" "this" {
  name    = "security-headers-policy"
  comment = "Standard security headers for static site"

  security_headers_config {
    strict_transport_security {
      override                   = true
      access_control_max_age_sec = 63072000
      include_subdomains         = true
      preload                    = true
    }

    content_type_options {
      override = true
    }

    frame_options {
      override     = true
      frame_option = "DENY"
    }

    referrer_policy {
      override        = true
      referrer_policy = "strict-origin-when-cross-origin"
    }

    content_security_policy {
      override                = true
      content_security_policy = "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self'; frame-ancestors 'none'; base-uri 'self'; form-action 'self'"
    }
  }
}

resource "aws_cloudfront_distribution" "this" {
  aliases = ["seanboaden.dev"]

  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
    origin_id                = local.s3_origin_id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id = local.s3_origin_id
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]

    cache_policy_id        = data.aws_cloudfront_cache_policy.caching_disabled.id
    viewer_protocol_policy = "redirect-to-https"

    response_headers_policy_id = aws_cloudfront_response_headers_policy.this.id
  }

  ordered_cache_behavior {
    path_pattern     = "/favicon/*"
    target_origin_id = local.s3_origin_id

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    cache_policy_id = aws_cloudfront_cache_policy.year_long_cache.id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    response_headers_policy_id = aws_cloudfront_response_headers_policy.this.id
  }

  ordered_cache_behavior {
    path_pattern     = "/images/*"
    target_origin_id = local.s3_origin_id

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    cache_policy_id = aws_cloudfront_cache_policy.year_long_cache.id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    response_headers_policy_id = aws_cloudfront_response_headers_policy.this.id
  }

  ordered_cache_behavior {
    path_pattern     = "/fonts/*"
    target_origin_id = local.s3_origin_id

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    cache_policy_id = aws_cloudfront_cache_policy.year_long_cache.id

    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    response_headers_policy_id = aws_cloudfront_response_headers_policy.this.id
  }

  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.viewer_certificate_arn
    ssl_support_method  = "sni-only"
  }

  custom_error_response {
    response_page_path    = "/index.html"
    error_code            = 403
    response_code         = 200
    error_caching_min_ttl = 10
  }
}

# Managed cache (https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html#managed-cache-policy-caching-disabled)
data "aws_cloudfront_cache_policy" "caching_disabled" {
  id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
}

# Custom cache policy
resource "aws_cloudfront_cache_policy" "year_long_cache" {
  name = "year-long-cache"

  min_ttl     = 31536000
  default_ttl = 31536000
  max_ttl     = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# IAM permissions for CI/CD

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    sid     = "GithubOidcAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.gh_repo}:environment:production"]
    }
  }
}

resource "aws_iam_role" "github_actions_role" {
  name               = "${var.project_name}-actions-deploy-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

data "aws_iam_policy_document" "deployment_policy" {
  statement {
    sid       = "AllowS3RecursiveCopy"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:ListBucket"]
    effect    = "Allow"
    resources = ["${aws_s3_bucket.this.arn}/*", "${aws_s3_bucket.this.arn}"]
  }
  statement {
    sid       = "AllowCloudFrontInvalidation"
    actions   = ["cloudfront:CreateInvalidation"]
    effect    = "Allow"
    resources = ["${aws_cloudfront_distribution.this.arn}"]
  }
}

resource "aws_iam_role_policy" "github_actions_deployment_policy" {
  name   = "${var.project_name}-deployment-permissions-s3-cloudfront"
  role   = aws_iam_role.github_actions_role.name
  policy = data.aws_iam_policy_document.deployment_policy.json
}

