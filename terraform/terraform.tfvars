project_name = "gametracker"
environment  = "dev"
aws_region   = "eu-west-3"

vpc_cidr                  = "10.0.0.0/16"
public_subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]
private_app_subnet_cidrs  = ["10.0.10.0/24", "10.0.11.0/24"]
private_data_subnet_cidrs = ["10.0.20.0/24", "10.0.21.0/24"]
availability_zones        = ["eu-west-3a", "eu-west-3b"]

spring_datasource_username = "gametracker"
rds_password               = "MotDePasseSolide!"   # 8 à 41 caractères, sans / @ " ni espace

cloudinary_cloud_name = "..."
cloudinary_api_key    = "..."
cloudinary_api_secret = "..."
jwt_secret            = "..."

restore_db_from_snapshot = false   # passer à true après le premier destroy
