####################################
# Subnet group (les 2 subnets private_data)
####################################

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_data_subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Project     = var.project_name
    Environment = var.environment
  }
}

####################################
# Restauration depuis le dernier snapshot (option A)
####################################

# Lu seulement si restore_from_snapshot = true
# (sinon la data source échouerait au tout premier apply, faute de snapshot)
data "aws_db_snapshot" "latest" {
  count = var.restore_from_snapshot ? 1 : 0

  db_instance_identifier = "${var.project_name}-${var.environment}-db"
  snapshot_type          = "manual" # les snapshots finaux sont de type "manual"
  most_recent            = true
}

# Suffixe aléatoire : le nom du snapshot final doit être unique à chaque destroy.
# Il est généré à la création de l'instance et reste stable pendant toute sa vie.
resource "random_id" "final_snapshot" {
  byte_length = 4
}

####################################
# Instance RDS MySQL
####################################

resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-${var.environment}-db"

  engine                     = "mysql"
  engine_version             = "8.4"
  auto_minor_version_upgrade = true

  instance_class    = var.instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  # Base créée seulement sur une instance neuve (un snapshot contient déjà la sienne)
  db_name  = var.restore_from_snapshot ? null : var.db_name
  username = var.db_username
  password = var.db_password

  snapshot_identifier = var.restore_from_snapshot ? data.aws_db_snapshot.latest[0].id : null

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_sg_id]
  publicly_accessible    = false
  multi_az               = false # Multi-AZ non couvert par le free tier

  backup_retention_period = var.backup_retention_period
  delete_automated_backups = true

  # Snapshot final au destroy
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.project_name}-${var.environment}-db-final-${random_id.final_snapshot.hex}"
  copy_tags_to_snapshot     = true
  deletion_protection       = false # sinon terraform destroy échoue

  apply_immediately = true

  lifecycle {
    # Sans ça, chaque nouveau snapshot ou un changement de restore_from_snapshot
    # forcerait le remplacement de la base existante
    ignore_changes = [snapshot_identifier, db_name]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-db"
    Project     = var.project_name
    Environment = var.environment
  }
}