variable "region" {
  type        = string
  description = "Region to request the certificate in (must be us-east-1 for CloudFront)."
}

variable "domain" {
  description = "FQDN to issue the certificate for (must be covered by the Cloudflare zone)."
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional SANs to include in the certificate. Duplicates and the main domain are removed automatically."
  type        = set(string)
  default     = []
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID that covers all certificate domains."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the ACM certificate."
  type        = map(string)
  default     = {}
}
