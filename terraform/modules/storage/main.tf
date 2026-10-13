resource "aws_s3_bucket" "mysql_backups" {
  bucket = "${var.project_name}-${var.environment}-mysql-backups"

  tags = {
    Name        = "${var.project_name}-${var.environment}-mysql-backups"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "mysql_backups" {
  bucket = aws_s3_bucket.mysql_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "mysql_backups" {
  bucket = aws_s3_bucket.mysql_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "mysql_backups" {
  bucket = aws_s3_bucket.mysql_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "mysql_backups" {
  bucket = aws_s3_bucket.mysql_backups.id

  rule {
    id     = "cleanup"
    status = "Enabled"

    filter {}

    expiration {
      expired_object_delete_marker = true
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}
