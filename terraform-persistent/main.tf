module "registry" {
  source = "../terraform/modules/registry"

  project_name = var.project_name
  environment  = var.environment
}

module "storage" {
  source = "../terraform/modules/storage"

  project_name = var.project_name
  environment  = var.environment
}