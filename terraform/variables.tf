variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "project_name" {
  type        = string
  description = "Project name"
}

variable "environment" {
  type        = string
  description = "Environment name"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR du VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones utilisées"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR des subnets publics"
}

variable "private_app_subnet_cidrs" {
  type        = list(string)
  description = "CIDR des subnets privés APP"
}

variable "private_data_subnet_cidrs" {
  type        = list(string)
  description = "CIDR des subnets privés DATA"
}

variable "spring_datasource_url" {
  type = string
}

variable "spring_datasource_username" {
  type = string
}

variable "cloudinary_cloud_name" {
  type = string
}

variable "cloudinary_api_key" {
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

variable "cloudinary_api_secret" {
  type      = string
  sensitive = true
}

variable "jwt_secret" {
  type      = string
  sensitive = true
}