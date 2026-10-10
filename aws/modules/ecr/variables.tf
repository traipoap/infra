variable "region" {
  type    = string
  description = "Region for this project"
}

variable "repository_name" {
  type        = string
  description = "Private Repository name"
}

variable "image_mutability" {
  type        = string
  default     = "MUTABLE"
  description = "MUTABLE or IMMUTABLE"
}

variable "force_destroy" {
  type        = bool
  default     = false
  description = "If true, deleting the repository will delete all images inside it"
}
