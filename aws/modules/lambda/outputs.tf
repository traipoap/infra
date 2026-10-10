output "lambda_function_url" {
  description = "Lambda URL for configuring the source domain name in CloudFront."
  value       = aws_lambda_function_url.app_url.function_url
}
