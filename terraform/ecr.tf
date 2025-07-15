resource "aws_ecr_repository" "app_repo" {
  name                 = "${var.env}-app-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.env}-app-repo"
  }
}