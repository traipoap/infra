variable "region" {
  type    = string
  description = "Region for this project"
}

variable "function_name" {
  type        = string
  description = "Function name"
}

variable "lambda_role_arn" {
  type        = string
  description = "ARN of the IAM execution role for the Lambda function"
}

variable "container_image_uri" {
  type        = string
  description = "ECR Image URI (e.g. 881050426069.dkr.ecr.ap-southeast-1.amazonaws.com/backend:latest)"
}

variable "cors_origins" {
  type        = string
  description = "URL to Backend"
}

variable "jwt_secret" {
  type      = string
  description = "JWT for Backend"
}

variable "database_path" {
  type        = string
  description = "SQLite path inside the Lambda container"
}

variable "quickwit_url" {
  type        = string
  default     = "The backend app use to access to searcher"
}

variable "base_path" {
  type        = string
  description = "Base path for the Lambda function"
}
