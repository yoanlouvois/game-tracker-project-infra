variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "front_repository_arn" {
  type = string
}

variable "back_repository_arn" {
  type = string
}

variable "backend_secret_arn" {
  type = string
}

variable "mysql_secret_arn" {
  type = string
}

variable "mysql_backups_bucket_arn" {
  type = string
}
