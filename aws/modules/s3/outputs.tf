output "bucket_name" {
  description = "S3 Bucket name"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "S3 Bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "S3 Bucket domain name (for CloudFront / Route53)"
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "S3 Bucket regional domain name"
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_hosted_zone_id" {
  description = "Route53 hosted zone ID for the S3 Bucket"
  value       = aws_s3_bucket.this.hosted_zone_id
}
