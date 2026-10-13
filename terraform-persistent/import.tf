import {
  to = module.registry.aws_ecr_repository.front
  id = "gametracker-dev-front"
}

import {
  to = module.registry.aws_ecr_repository.back
  id = "gametracker-dev-back"
}

import {
  to = module.storage.aws_s3_bucket.mysql_backups
  id = "gametracker-dev-mysql-backups"
}