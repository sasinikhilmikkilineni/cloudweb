output "cloudfront_domain" {
  value = aws_cloudfront_distribution.frontend.domain_name
}

output "frontend_bucket_name" {
  value = aws_s3_bucket.frontend.bucket
}

output "apprunner_url" {
  value = aws_apprunner_service.api.service_url
}
