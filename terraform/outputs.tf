output "alb_dns_name" {
  description = "DNS de l'ALB"
  value       = module.load_balancing.alb_dns_name
}

output "app_url" {
  description = "URL de l'application"
  value       = "http://${module.load_balancing.alb_dns_name}"
}