# ==============================================================================
# RDS Module (PostgreSQL)
# ==============================================================================
# Provisions a Managed PostgreSQL Database Instance.
# Features:
# - Private Subnet Placement (Security)
# - Automated Backups & Maintenance Windows
# - Performance Insights (Monitoring)
# - Custom Parameter Group (Logging/Optimization)

resource "aws_db_subnet_group" "this" {
  count = var.create_rds ? 1 : 0

  name       = var.subnet_group_name_override != null ? var.subnet_group_name_override : "${var.env}-${var.name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = var.subnet_group_name_override != null ? var.subnet_group_name_override : "${var.env}-${var.name}-subnet-group"
  })
}

resource "aws_db_instance" "this" {
  count = var.create_rds ? 1 : 0

  identifier     = "${var.env}-${var.name}-db"
  engine         = "postgres"
  engine_version = var.engine_version

  instance_class    = var.instance_class    # e.g. db.t3.micro (cheap) vs db.m5.large (perf)
  allocated_storage = var.allocated_storage # Storage in GB
  storage_type      = var.storage_type
  storage_encrypted = true

  db_name  = var.database_name
  username = var.master_username
  password = var.master_password
  port     = var.database_port

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.this[0].name
  vpc_security_group_ids = [var.rds_sg_id]
  publicly_accessible    = var.publicly_accessible # False (Private) for Prod

  # Single AZ deployment (Cost saving)
  multi_az = false

  # Backup Configuration
  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"         # 3-4 AM UTC
  maintenance_window      = "mon:04:00-mon:05:00" # Monday 4-5 AM UTC

  # Deletion Protection (Prevent accidental data loss)
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.env}-postgres-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Performance Insights
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]
  performance_insights_enabled          = var.enable_performance_insights
  performance_insights_retention_period = var.enable_performance_insights ? 7 : null

  auto_minor_version_upgrade = true

  parameter_group_name = aws_db_parameter_group.this[0].name

  tags = merge(var.tags, {
    Name = "${var.env}-${var.name}-db"
  })

  lifecycle {
    prevent_destroy = true
  }

  apply_immediately = var.apply_immediately
}

# Custom Parameter Group
# Fine-tune PostgreSQL settings
resource "aws_db_parameter_group" "this" {
  count = var.create_rds ? 1 : 0

  name   = "${var.env}-${var.name}-params"
  family = var.parameter_group_family

  # Enable Query Statistics
  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }

  # Query Logging
  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000" # Log slow queries (>1s)
  }

  tags = merge(var.tags, {
    Name = "${var.env}-${var.name}-params"
  })
}
