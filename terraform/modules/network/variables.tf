variable "project_name" {
  type        = string
  description = "Nom du projet"
}

variable "environment" {
  type        = string
  description = "Environnement"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR du VPC"
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

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones utilisées"
}

variable "aws_region" {
  type = string
}