variable "distribution_name" {
  type        = string
  description = "Name of the S3 bucket. Must be globally unique and lowercase."
}

variable "domain_name" {
  type = string
}

variable "primary_origin_domain" {
  type        = string
  description = "Primary origin (K3s ingress) FQDN to try before failing over to S3/Lambda."
}

variable "api_proxy_target" {
  type = string
}

variable "bucket_regional_domain_name" {
  type = string
}

variable "certificate_arn" {
  type = string
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone ID for creating the CNAME record of `domain_name`. Set to an empty string to skip DNS management."
  default     = ""
}

variable "aws_access_key" {
  type        = string
  description = "AWS access key ID for the local-exec CloudFront invalidation. Leave empty to skip the invalidation."
  default     = ""
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  description = "AWS secret access key for the local-exec CloudFront invalidation. Leave empty to skip the invalidation."
  default     = ""
  sensitive   = true
}
