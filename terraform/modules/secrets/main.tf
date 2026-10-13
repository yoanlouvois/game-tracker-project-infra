resource "aws_ssm_parameter" "spring_datasource_username" {
  name  = "/${var.project_name}/${var.environment}/spring/datasource/username"
  type  = "String"
  value = var.spring_datasource_username
}

resource "aws_ssm_parameter" "cloudinary_cloud_name" {
  name  = "/${var.project_name}/${var.environment}/cloudinary/cloud-name"
  type  = "String"
  value = var.cloudinary_cloud_name
}

resource "aws_ssm_parameter" "cloudinary_api_key" {
  name  = "/${var.project_name}/${var.environment}/cloudinary/api-key"
  type  = "String"
  value = var.cloudinary_api_key
}

resource "aws_secretsmanager_secret" "backend" {
  name                    = "${var.project_name}/${var.environment}/backend"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "backend" {
  secret_id = aws_secretsmanager_secret.backend.id

  secret_string = jsonencode({
    SPRING_DATASOURCE_PASSWORD = var.spring_datasource_password
    CLOUDINARY_API_SECRET      = var.cloudinary_api_secret
    JWT_SECRET                 = var.jwt_secret
  })
}