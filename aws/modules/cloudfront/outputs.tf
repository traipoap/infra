output "distribution_domain" {
  description = "CloudFront distribution domain name to CNAME to."
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "distribution_arn" {
  value = aws_cloudfront_distribution.s3_distribution.arn
}

output "distribution_oac_id" {
  value = aws_cloudfront_origin_access_control.oac.id
}
