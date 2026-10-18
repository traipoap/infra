resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-astro-oac"
  description                       = "OAC for Astro Static Website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_function" "astro_router" {
  name    = "${var.distribution_name}-astro-router"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite request URI for Astro clean URLs"
  publish = true
  code    = <<-EOF
      function handler(event) {
          var request = event.request;
          var uri = request.uri;

          // Rewrite URI สำหรับ Static Files / Astro Router
          if (uri.endsWith('/')) {
              request.uri += 'index.html';
          } else if (!uri.includes('.')) {
              request.uri += '/index.html';
          }

          return request;
      }
    EOF
}

resource "aws_cloudfront_distribution" "s3_distribution" {

  origin {
    domain_name              = var.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = "S3-${var.distribution_name}"
  }

  origin {
    domain_name = var.api_proxy_target
    origin_id   = "Lambda-API-Target"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Shared primary origin: the K3s ingress (Astro static via nginx + Gin API).
  # First member of both origin groups below.
  origin {
    domain_name = var.primary_origin_domain
    origin_id   = "K3s-Origin"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # API path failover group: try K3s first, fall back to Lambda on 500/502/503/504.
  origin_group {
    origin_id = "K3s-Lambda-OriginGroup"

    failover_criteria {
      status_codes = [404, 500, 502, 503, 504]
    }

    member {
      origin_id = "K3s-Origin"
    }

    member {
      origin_id = "Lambda-API-Target"
    }
  }

  # Static site failover group: try K3s first, fall back to the S3 Astro bucket on 500/502/503/504.
  origin_group {
    origin_id = "K3s-S3-OriginGroup"

    failover_criteria {
      status_codes = [404, 500, 502, 503, 504]
    }

    member {
      origin_id = "K3s-Origin"
    }

    member {
      origin_id = "S3-${var.distribution_name}"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name]

  # API behavior: no caching (TTLs 0), all HTTP methods allowed, and
  # query strings / cookies / auth headers are forwarded to the origin —
  # what the Gin API needs. Keeps the K3s→Lambda failover.
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "K3s-Origin"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Origin", "Accept"]

      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # No caching: every request goes to the origin (K3s first, S3 on 5xx).
  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "K3s-S3-OriginGroup"

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.astro_router.arn
    }
  }

  custom_error_response {
    error_code            = 403
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 404
    response_page_path    = "/404.html"
    error_caching_min_ttl = 10
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# Flush the edge cache when the distribution is created or replaced (clears
# stale objects cached under a previous configuration). With unchanged args,
# later applies do nothing; to force a flush on demand run:
#   terraform apply -replace=module.cloudfront.null_resource.cloudfront_invalidate
# Skipped entirely when no AWS keys are passed (module used standalone).
resource "null_resource" "cloudfront_invalidate" {
  count    = var.aws_access_key == "" || var.aws_secret_key == "" ? 0 : 1
  triggers = {
    distribution_id = aws_cloudfront_distribution.s3_distribution.id
  }

  depends_on = [aws_cloudfront_distribution.s3_distribution]

  provisioner "local-exec" {
    command     = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.s3_distribution.id} --paths \"/*\""
    environment = {
      AWS_ACCESS_KEY_ID     = var.aws_access_key
      AWS_SECRET_ACCESS_KEY = var.aws_secret_key
      AWS_REGION           = "us-east-1" # CloudFront is global; region only satisfies the CLI
    }
  }
}

# Point the app domain at the distribution (grey-cloud / DNS-only).
# Managed here so the CNAME always tracks the current distribution's
# domain_name — a stale manually-created CNAME is what breaks re-applies.
resource "cloudflare_dns_record" "app_cname" {
  count   = var.cloudflare_zone_id == "" ? 0 : 1
  zone_id = var.cloudflare_zone_id
  name    = var.domain_name
  type    = "CNAME"
  content = trimsuffix(aws_cloudfront_distribution.s3_distribution.domain_name, ".")
  ttl     = 1
  proxied = false
}
