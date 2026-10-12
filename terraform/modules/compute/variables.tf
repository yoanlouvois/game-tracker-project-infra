variable "project_name" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }

variable "private_app_subnet_ids" { type = list(string) }
variable "private_data_subnet_ids" { type = list(string) }

variable "front_sg_id" { type = string }
variable "back_sg_id" { type = string }
variable "mysql_sg_id" { type = string }

variable "front_instance_profile_name" { type = string }
variable "back_instance_profile_name" { type = string }
variable "mysql_instance_profile_name" { type = string }

variable "front_repository_url" { type = string }
variable "back_repository_url" { type = string }

variable "front_target_group_arn" { type = string }
variable "back_target_group_arn" { type = string }

variable "mysql_backups_bucket_name" { type = string }

variable "instance_type_app" {
  type    = string
  default = "t3.micro"
}

variable "instance_type_mysql" {
  type    = string
  default = "t3.micro"
}

variable "mysql_ebs_size" {
  type    = number
  default = 30
}

variable "spring_datasource_username" {
  type = string
}

variable "spring_datasource_password" {
  type      = string
  sensitive = true
}

variable "mysql_root_password" {
  type      = string
  sensitive = true
}