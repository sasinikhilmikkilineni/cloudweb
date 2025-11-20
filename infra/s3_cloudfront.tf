# Private S3 bucket for React/Vite build
resource "aws_s3_bucket" "frontend" {
  bucket = var.frontend_bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFront OAC for S3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${local.name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront: S3 (default) + App Runner for /api/*
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  aliases             = [] # use default CF domain for speed; add your domain later
  default_root_object = "index.html"

  # S3 origin
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # App Runner origin
  origin {
    domain_name = replace(aws_apprunner_service.api.service_url, "https://", "")
    origin_id   = "apprunner-api"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default behavior: static site from S3
  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    forwarded_values {
      query_string = true
      cookies { forward = "none" }
    }
  }

  # API: no caching, forward auth/CORS headers
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "apprunner-api"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true
    forwarded_values {
      query_string = true
      headers = [
        "Authorization",
        "Content-Type",
        "Origin",
        "Referer",
        "Accept",
        "Accept-Language",
        "Access-Control-Request-Method",
        "Access-Control-Request-Headers"
      ]
      cookies { forward = "all" }
    }
    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # SPA deep-link fallback
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }
  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 0
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction { restriction_type = "none" }
  }

  # Default CF certificate (no custom domain needed)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = local.tags
}

# Bucket policy for OAC
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.s3_policy.json
}
