# Provider
variable "aws_region" {
  type        = string
  description = "Default AWS region for resource provisioning (e.g., ap-southeast-1)"
}

variable "aws_access_key" {
  type        = string
  description = "AWS access key ID used to authenticate with the AWS provider"
  sensitive   = true
}

variable "aws_secret_key" {
  type        = string
  description = "AWS secret access key used to authenticate with the AWS provider"
  sensitive   = true
}

variable "environment" {
  type        = string
  description = "Deployment environment name (e.g., dev, staging, prod)"
}

variable "cloudflare_api_token" {
  type        = string
  description = "Cloudflare api token use to validate ACM"
}

# IAM
variable "role_name" {
  type        = string
  description = "Application name used for IAM roles and resource naming"
}

# ECR
variable "repository_name" {
  type = string
}

variable "container_image_uri" {
  type        = string
  description = "ECR image URI of the container to deploy (e.g., 881050426069.dkr.ecr.ap-southeast-1.amazonaws.com/backend:latest)"
}

# ACM
variable "domain_name" {
  type        = string
  description = "Primary domain for the ACM certificate (e.g., *.traipoap.com)"
}

variable "subject_alternative_names" {
  type        = list(string)
  description = "Additional alternate domain names (SANs) for the ACM certificate"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone id for acm validation"
}

# S3
variable "bucket_name" {
  type        = string
  description = "S3 bucket name for the static website"
}

# Cloudfront
variable "distribution_name" {
  type = string
}

variable "app_domain_name" {
  type        = string
  description = "Fully qualified domain name (FQDN) served through CloudFront (e.g., aws-app.traipoap.com)"
}

variable "k3s_origin_domain" {
  type        = string
  description = "Primary origin (K3s ingress) FQDN, tried before failing over to S3/Lambda"
}

# Lambda
variable "function_name" {

}
variable "cors_origins" {
  type        = string
  description = "Allowed CORS origins for the API (e.g., * or a specific origin)"
}

variable "database_path" {
  type        = string
  description = "Filesystem path to the SQLite database file"
}

variable "jwt_secret" {
  type        = string
  description = "Secret used to sign and verify JWT tokens"
  sensitive   = true
}

variable "quickwit_url" {
  type        = string
  description = "The backend app use to access to searcher"
}

variable "base_path" {
  type        = string
  description = "Base path for the Lambda function"
}
