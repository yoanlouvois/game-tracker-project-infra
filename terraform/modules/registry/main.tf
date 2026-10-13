resource "aws_ecr_repository" "front" {
  name                 = "${var.project_name}-${var.environment}-front"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-front-ecr"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "back" {
  name                 = "${var.project_name}-${var.environment}-back"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-back-ecr"
    Project     = var.project_name
    Environment = var.environment
  }
}

locals {
  ecr_lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Supprimer les images non taggees apres 7 jours"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Garder les 10 dernieres images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "front" {
  repository = aws_ecr_repository.front.name
  policy     = local.ecr_lifecycle_policy
}

resource "aws_ecr_lifecycle_policy" "back" {
  repository = aws_ecr_repository.back.name
  policy     = local.ecr_lifecycle_policy
}