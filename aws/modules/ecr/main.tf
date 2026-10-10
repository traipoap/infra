resource "aws_ecr_repository" "this" {
  region               = var.region
  name                 = var.repository_name
  image_tag_mutability = var.image_mutability
  force_delete         = var.force_destroy

  image_scanning_configuration {
    scan_on_push = true
  }
}
