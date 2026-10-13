####################################
# Ressources persistantes (gérées par terraform-persistent, ici en lecture seule)
####################################

data "aws_ecr_repository" "front" {
  name = "${var.project_name}-${var.environment}-front"
}

data "aws_ecr_repository" "back" {
  name = "${var.project_name}-${var.environment}-back"
}

####################################
# Réseau et sécurité
####################################

module "network" {
  source = "./modules/network"

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  vpc_cidr                  = var.vpc_cidr
  public_subnet_cidrs       = var.public_subnet_cidrs
  private_app_subnet_cidrs  = var.private_app_subnet_cidrs
  private_data_subnet_cidrs = var.private_data_subnet_cidrs
  availability_zones        = var.availability_zones
}

module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.network.vpc_id
}

####################################
# Secrets et IAM
####################################

module "secrets" {
  source = "./modules/secrets"

  project_name = var.project_name
  environment  = var.environment

  spring_datasource_username = var.spring_datasource_username
  cloudinary_cloud_name      = var.cloudinary_cloud_name
  cloudinary_api_key         = var.cloudinary_api_key

  spring_datasource_password = var.rds_password
  cloudinary_api_secret      = var.cloudinary_api_secret
  jwt_secret                 = var.jwt_secret
}

module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment

  front_repository_arn = data.aws_ecr_repository.front.arn
  back_repository_arn  = data.aws_ecr_repository.back.arn

  backend_secret_arn = module.secrets.backend_secret_arn
}

####################################
# Base de données (RDS)
####################################

module "database" {
  source = "./modules/database"

  project_name = var.project_name
  environment  = var.environment

  private_data_subnet_ids = module.network.private_data_subnet_ids
  db_sg_id                = module.security.mysql_sg_id

  db_username = var.spring_datasource_username
  db_password = var.rds_password

  restore_from_snapshot = var.restore_db_from_snapshot
}

####################################
# Load balancing et compute
####################################

module "load_balancing" {
  source = "./modules/load_balancing"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
}

module "compute" {
  source = "./modules/compute"

  # Les instances ne démarrent qu'une fois les droits IAM attachés et la NAT routée
  depends_on = [module.iam, module.network]

  project_name = var.project_name
  environment  = var.environment
  aws_region   = var.aws_region

  private_app_subnet_ids = module.network.private_app_subnet_ids

  front_sg_id = module.security.front_sg_id
  back_sg_id  = module.security.back_sg_id

  front_instance_profile_name = module.iam.front_instance_profile_name
  back_instance_profile_name  = module.iam.back_instance_profile_name

  front_repository_url = data.aws_ecr_repository.front.repository_url
  back_repository_url  = data.aws_ecr_repository.back.repository_url

  front_target_group_arn = module.load_balancing.front_target_group_arn
  back_target_group_arn  = module.load_balancing.back_target_group_arn

  db_address                 = module.database.db_address
  spring_datasource_username = var.spring_datasource_username
}

####################################
# CDN
####################################

module "cdn" {
  source = "./modules/cdn"

  project_name = var.project_name
  environment  = var.environment
  alb_dns_name = module.load_balancing.alb_dns_name
}