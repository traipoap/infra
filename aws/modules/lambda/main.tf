resource "aws_lambda_function" "app" {
  function_name = var.function_name
  role          = var.lambda_role_arn
  package_type  = "Image"
  image_uri     = var.container_image_uri
  memory_size   = 128
  timeout       = 10

  environment {
    variables = {
      CORS_ORIGINS      = var.cors_origins
      DATABASE_PATH     = var.database_path
      JWT_SECRET        = var.jwt_secret
      QUICKWIT_URL      = var.quickwit_url
      BASE_PATH        = var.base_path
    }
  }
}

resource "aws_lambda_function_url" "app_url" {
  function_name      = aws_lambda_function.app.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["${var.cors_origins}"]
    allow_methods     = ["GET", "POST", "DELETE"]
    allow_headers     = ["*"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }

  depends_on = [aws_lambda_function.app]
}

resource "aws_lambda_permission" "allow_public_url" {
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.app.function_name
  principal              = "*"
  function_url_auth_type = "NONE"

  depends_on = [aws_lambda_function.app]
}
