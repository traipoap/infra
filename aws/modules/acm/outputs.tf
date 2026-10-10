output "certificate_arn" {
  description = "ARN of the issued (validated) ACM certificate."
  value       = aws_acm_certificate_validation.this.certificate_arn
}

output "certificate_domain" {
  description = "Domain of the issued certificate."
  value       = aws_acm_certificate.this.domain_name
}
