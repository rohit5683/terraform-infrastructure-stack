# ==============================================================================
# Security Groups (Dev & Stage)
# ==============================================================================
# Defines firewall rules for the Development and Staging environments.
# Contains:
# - ALB SG: Public access (80/443)
# - Frontend ECS SG: Accepts only from ALB
# - Backend ECS SG: Accepts only from ALB
# - RDS SG: Accepts from Backend (and Jump host)
# - Redis SG: Accepts from Backend

# ALB Security Group
# Public facing - Allow HTTP/HTTPS from everywhere
resource "aws_security_group" "alb_sg" {
  name        = "${var.env}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

}

# Frontend ECS SG (Public Fargate Tasks in Dev/Stage)
resource "aws_security_group" "frontend_ecs_sg" {
  name        = "${var.env}-frontend-ecs-sg"
  description = "Security group for frontend ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Only ALB can reach frontend
  }

  # Outbound Access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Backend ECS SG (Private Fargate Tasks)
resource "aws_security_group" "backend_ecs_sg" {
  name        = "${var.env}-backend-ecs-sg"
  description = "Security group for backend ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow ALB to access backend on port 3000"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Only ALB can reach backend
  }

  # Outbound Access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "${var.env}-rds-sg"
  description = "Allow backend ECS to reach RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow backend ECS to access RDS on port 5432"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_ecs_sg.id] # Only backend ECS can reach RDS
  }

  ingress {
    description     = "Allow Lambda to access RDS on port 5432"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
  }

  ingress {
    description     = "Allow Redis (Bastion) to access RDS on port 5432"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.redis_sg.id]
  }

  # Public access setting (Only enabled if rds_public_access = true, typically for Dev)
  dynamic "ingress" {
    for_each = var.rds_public_access ? [1] : []
    content {
      description = "Allow public access to RDS"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

}

# Redis Security Group
# Used for Elasticache and sometimes as a Bastion/Jump host in Dev.
resource "aws_security_group" "redis_sg" {
  name        = "${var.env}-redis-sg"
  description = "Security group for Redis"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow backend ECS to access Redis on port 6379"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Lambda Security Group
resource "aws_security_group" "lambda_sg" {
  name        = "${var.env}-lambda-sg"
  description = "Security group for lambda functions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
