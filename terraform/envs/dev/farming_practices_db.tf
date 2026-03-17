# ==============================================================================
# FARMING PRACTICES DATABASE
# ==============================================================================
# This database is publicly accessible and shared between Dev and Stage environments.
# Primarily used by the ML engineering team.

resource "aws_security_group" "farming_db_sg" {
  name        = "${var.env}-farming-db-sg"
  description = "Security group for Farming Practices DB (Public + Dev/Stage Access)"
  vpc_id      = module.vpc.vpc_id

  # Public access for ML Engineers
  ingress {
    description = "Allow public access for ML Engineers"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Recommendation: Restrict to specific IPs in production-like scenarios
  }

  # Internal access for Dev Backend
  ingress {
    description     = "Allow Dev backend ECS to access"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.sg.backend_ecs_sg_id]
  }

  # Access for Stage (pointing to this DB via public IP since they are in different VPCs)
  # CIDR for Stage VPC: 10.11.0.0/16
  ingress {
    description = "Allow Stage VPC access (via NAT Gateway/Public IP)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr, "10.11.0.0/16"] # Including both Dev and Stage CIDRs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.env
    Name        = "${var.env}-farming-db-sg"
  }
}

module "farming_rds" {
  source = "../../modules/rds"

  env                 = var.env
  create_rds          = true
  subnet_ids          = module.vpc.public_subnets # Public subnets for visibility
  rds_sg_id           = aws_security_group.farming_db_sg.id
  publicly_accessible = true

  # Standardized naming: will create dev-farming-db, dev-farming-params, etc.
  name = "farming"

  # Database Configuration 
  database_name   = var.FARMING_DB_NAME
  database_port   = var.FARMING_DB_PORT
  master_username = var.FARMING_DB_USER
  master_password = var.FARMING_DB_PASS

  # Instance Configuration
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  backup_retention_period = var.backup_retention_period

  tags = {
    Environment = var.env
    Name        = "${var.env}-farming-practices-db"
  }
}

output "farming_db_address" {
  value       = module.farming_rds.db_address
  description = "The hostname of the farming practices database"
}
