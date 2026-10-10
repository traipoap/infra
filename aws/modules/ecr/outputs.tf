output "ecr_repository_url" {
  description = "ECR Repository URL สำหรับนำไป push Image จาก GitHub Actions หรือ Docker CLI"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "Full ARN of the repository"
  value       = aws_ecr_repository.this.arn
}
