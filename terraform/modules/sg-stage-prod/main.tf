# ==============================================================================
# Security Groups (Production)
# ==============================================================================
# Defines stricter firewall rules for Production.
# Key differences:
# - Frontend ALB ingress restricted to CloudFront Prefix List (no open internet)
# - Internal ALB for backend traffic
# - API Gateway Integration

# 1. API Gateway VPC Link SG
# Controls traffic from API Gateway into the VPC
resource "aws_security_group" "apigw_vpclink_sg" {
  name        = "${var.env}-apigw-vpclink-sg"
  description = "API Gateway VPC Link to Backend Internal ALB"
  vpc_id      = var.vpc_id

  # No inbound rules required here; Security Groups are stateful.
  # The VPC Link acts as a tunnel.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# 2. Backend Internal ALB SG
# Balances traffic for the backend API
resource "aws_security_group" "backend_alb_sg" {
  name        = "${var.env}-backend-alb-sg"
  description = "Internal ALB for backend"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow API Gateway via VPC Link"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.apigw_vpclink_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = var.tags

}

# 3. Backend ECS SG
# The actual NestJS containers
resource "aws_security_group" "backend_ecs_sg" {
  name        = "${var.env}-backend-ecs-sg"
  description = "Backend ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow backend ALB to reach backend ECS (3000)"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

}

# 4. RDS SG
# PostgreSQL Database
resource "aws_security_group" "rds_sg" {
  name        = "${var.env}-rds-sg"
  description = "PostgreSQL RDS Access"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend_ecs_sg.id]
    description     = "Allow backend ECS to access RDS"
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_sg.id]
    description     = "Allow Lambda to access RDS"
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.jump_ssm_sg.id]
    description     = "Allow Jump SSM EC2 to access RDS"
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.redis_sg.id]
    description     = "Allow Redis (Bastion) to access RDS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

}

# 5. EC2 SSM Jump SG
# Bastion host for database maintenance
resource "aws_security_group" "jump_ssm_sg" {
  name        = "${var.env}-ssm-jump-sg"
  description = "Jump EC2 SSM instance"
  vpc_id      = var.vpc_id

  # No inbound rules rules (SSM access is initiated outbound to AWS API)

  # Outbound: allow SSM to reach VPC endpoints
  egress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.vpc_endpoints_sg_id != "" ? [var.vpc_endpoints_sg_id] : []
    description     = "Allow SSM traffic to VPC endpoints (if created)"
  }

  # Allow all outbound for normal EC2 operations (includes RDS access)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Default outbound access"
  }

  tags = var.tags

}


# 6. Frontend ALB SG
# Public ALB for the React App
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "frontend_alb_sg" {
  name        = "${var.env}-frontend-alb-sg"
  description = "Public ALB for frontend, restricted to CloudFront"
  vpc_id      = var.vpc_id

  # Only CloudFront can access this ALB
  # Conditional Ingress: CloudFront Only (Prod)
  dynamic "ingress" {
    for_each = var.restrict_to_cloudfront ? [1] : []
    content {
      description     = "Allow HTTPS from CloudFront origin-facing prefix list"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
    }
  }

  # Conditional Ingress: Public Internet (Stage)
  # Open to 0.0.0.0/0 because Stage has no CloudFront.
  # Allow both 80 (for redirect) and 443.
  dynamic "ingress" {
    for_each = var.restrict_to_cloudfront ? [] : [1]
    content {
      description = "Allow HTTPS from everywhere"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  dynamic "ingress" {
    for_each = var.restrict_to_cloudfront ? [] : [1]
    content {
      description = "Allow HTTP from everywhere"
      from_port   = 80
      to_port     = 80
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

# 7. Frontend ECS SG
resource "aws_security_group" "frontend_ecs_sg" {
  name        = "${var.env}-frontend-ecs-sg"
  description = "Frontend ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow traffic from frontend ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.frontend_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags

}

# 8. Redis SG
resource "aws_security_group" "redis_sg" {
  name        = "${var.env}-redis-sg"
  description = "Redis Security Group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow Redis from Backend ECS"
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

# 9. Lambda Security Group
resource "aws_security_group" "lambda_sg" {
  name        = "${var.env}-lambda-sg"
  description = "Lambda functions access"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
