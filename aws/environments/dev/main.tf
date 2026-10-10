# Global region
module "iam" {
  source = "../../modules/iam"

  role_name = var.role_name
}

module "ecr" {
  source = "../../modules/ecr"

  region          = "ap-southeast-1"
  repository_name = var.repository_name
  force_destroy   = false
}

module "acm" {
  source = "../../modules/acm"

  region                    = "us-east-1"
  domain                    = var.domain_name
  subject_alternative_names = var.subject_alternative_names
  cloudflare_zone_id        = var.cloudflare_zone_id
}

module "s3" {
  source = "../../modules/s3"

  region              = "ap-southeast-7"
  bucket_name         = var.bucket_name
  force_destroy       = false
  s3_distribution_arn = module.cloudfront.distribution_arn
}

# Global region
module "cloudfront" {
  source = "../../modules/cloudfront"

  distribution_name           = var.distribution_name
  bucket_regional_domain_name = module.s3.bucket_regional_domain_name
  certificate_arn             = module.acm.certificate_arn
  domain_name                 = var.app_domain_name
  api_proxy_target            = replace(replace(module.lambda.lambda_function_url, "https://", ""), "/", "") # API_PROXY_TARGET
  primary_origin_domain       = var.k3s_origin_domain
  cloudflare_zone_id          = var.cloudflare_zone_id
  aws_access_key              = var.aws_access_key
  aws_secret_key              = var.aws_secret_key
}

module "lambda" {
  source = "../../modules/lambda"

  region              = "ap-southeast-1"
  function_name       = var.function_name
  lambda_role_arn     = module.iam.lambda_role_arn
  container_image_uri = var.container_image_uri
  cors_origins        = var.cors_origins
  jwt_secret          = var.jwt_secret
  database_path       = var.database_path
  quickwit_url        = var.quickwit_url
  base_path           = var.base_path
}
