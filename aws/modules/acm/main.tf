locals {
  # SANs, deduplicated and with the main domain removed (callers may include it).
  sans = setsubtract(var.subject_alternative_names, [var.domain])

  # All names that must be validated — known at plan time.
  domains = setunion([var.domain], local.sans)

  # Apply-time lookup map keyed by domain, used only in the *values*.
  dvo_by_domain = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => dvo
  }

  validation_records = {
    for d in local.domains : d => {
      name  = local.dvo_by_domain[d].resource_record_name
      type  = local.dvo_by_domain[d].resource_record_type
      value = local.dvo_by_domain[d].resource_record_value
      fqdn  = local.dvo_by_domain[d].resource_record_name
    }
  }
}

resource "aws_acm_certificate" "this" {
  region                    = var.region
  domain_name               = var.domain
  subject_alternative_names = local.sans
  validation_method         = "DNS"
  tags                      = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_dns_record" "acm_validation" {
  for_each = local.validation_records
  zone_id  = var.cloudflare_zone_id
  name     = trimsuffix(each.value.name, ".")
  type     = each.value.type
  content  = trimsuffix(each.value.value, ".")
  ttl      = 1
  proxied  = false
}

resource "aws_acm_certificate_validation" "this" {
  region                  = var.region
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for r in local.validation_records : r.fqdn]

  # Don't start polling AWS before the Cloudflare record exists — without
  # this dependency Terraform runs the two in parallel and may wait (up to
  # the create timeout) even though the record just hasn't landed yet.
  depends_on = [cloudflare_dns_record.acm_validation]

  timeouts {
    create = "2h"
  }
}
