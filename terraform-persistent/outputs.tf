output "front_repository_url" {
  value = module.registry.front_repository_url
}

output "back_repository_url" {
  value = module.registry.back_repository_url
}

output "mysql_backups_bucket_name" {
  value = module.storage.mysql_backups_bucket_name
}