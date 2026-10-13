variable "project_name" {
  type = string
}

variable "environment" {
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

variable "cloudinary_api_secret" {
  type      = string
  sensitive = true
}

variable "jwt_secret" {
  type      = string
  sensitive = true
}