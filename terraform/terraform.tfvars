aws_region   = "eu-west-3"
project_name = "gametracker"
environment  = "dev"

vpc_cidr = "10.0.0.0/16"

availability_zones = [
  "eu-west-3a",
  "eu-west-3b"
]

public_subnet_cidrs = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_app_subnet_cidrs = [
  "10.0.10.0/24",
  "10.0.11.0/24"
]

private_data_subnet_cidrs = [
  "10.0.20.0/24",
  "10.0.21.0/24"
]

spring_datasource_url      = "jdbc:mysql://10.0.20.15:3306/db_pgt?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true"
spring_datasource_username = "test"

cloudinary_cloud_name = "dhaektb1h"
cloudinary_api_key    = "766219817752778"

spring_datasource_password = "test"
mysql_root_password        = "Rafaela2003*"
cloudinary_api_secret      = "ds8IjkifIaHsovLWU71mX9r1D_Y"
jwt_secret                 = "YXNkZmFzZGZhc2RmYXNkZmFzZGZhc2RmYXNkZmFzZGZhc2RmYXNkZmFzZGZhc2Rm"

github_repositories = [
  "yoanlouvois/GameTrackerProject-Backend",
  "yoanlouvois/GameTrackerProject-Frontend"
]