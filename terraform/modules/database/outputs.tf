output "db_address" {
  description = "Nom DNS de l'instance RDS (sans le port)"
  value       = aws_db_instance.main.address
}

output "db_port" {
  value = aws_db_instance.main.port
}

output "db_name" {
  value = var.db_name
}