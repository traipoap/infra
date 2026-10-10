variable "region" {
  type    = string
  default = "ap-southeast-7"
  description = "Region for this project"
}

variable "bucket_name" {
  type        = string
  description = "S3 Bucket name. Must be globally unique and lowercase."
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "If true, delete all objects in the bucket on destroy. Useful for disposable buckets, dangerous for production data."
}

variable "s3_distribution_arn" {
  type        = string
}
