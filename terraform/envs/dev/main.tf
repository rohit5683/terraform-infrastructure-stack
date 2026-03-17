provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.env
      ManagedBy   = "Terraform"
      Project     = "rvdevops"
    }
  }
}

locals {
  app_domain = "app.${var.domain_name}"
  api_domain = "api.${var.domain_name}"
}

# ==============================================================================
# NETWORK & INFRASTRUCTURE
# ==============================================================================

# Virtual Private Cloud (VPC)
# Creates the networking foundation: VPC, public/private subnets, and route tables.
# Public subnets are for Load Balancers (and RDS in Dev), private subnets for ECS tasks.
module "vpc" {
  source               = "../../modules/vpc"
  name                 = "${var.env}-vpc"
  cidr_block           = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_vpc_endpoints = true
  region               = var.aws_region # REQUIRED for endpoints
  vpc_interface_endpoints = [
    "com.amazonaws.${var.aws_region}.ssm",
    "com.amazonaws.${var.aws_region}.ssmmessages",
    "com.amazonaws.${var.aws_region}.ec2messages"
  ]
  tags = {
    Environment = var.env
  }
}

# IAM Roles and Policies
# Creates execution roles for ECS tasks, allow pulling images, logging, etc.
module "iam" {
  source           = "../../modules/iam"
  env              = var.env
  region           = var.aws_region
  secrets_path_arn = "rvdevops/env/*"
}

# Security Groups
# Defines firewall rules for standard resources (ALB, DB, etc.)
module "sg" {
  source            = "../../modules/sg-dev"
  env               = var.env
  vpc_id            = module.vpc.vpc_id
  rds_public_access = true # Allow public access for Dev database
  tags = {
    Environment = var.env
  }
}

# ==============================================================================
# DOMAIN & SSL
# ==============================================================================

# Certificates (ACM)
# Provisions an SSL certificate for HTTPS (requires DNS validation).
module "acm" {
  source = "../../modules/acm"
  env    = var.env
  tags = {
    Environment = var.env
  }

  enable_route53_dns = var.enable_route53_dns
  zone_id            = var.enable_route53_dns ? module.route53[0].zone_id : null
}

# DNS Records (Route53)
# Creates A-records pointing 'app' and 'api' subdomains to the Load Balancer.
module "route53" {
  source = "../../modules/route53"
  count  = var.enable_route53_dns ? 1 : 0

  env           = var.env
  dns_zone_name = var.dns_zone_name

  records = {
    (local.app_domain) = {
      target_dns     = module.alb.public_alb_dns
      target_zone_id = module.alb.public_alb_zone_id
    }
    (local.api_domain) = {
      target_dns     = module.alb.public_alb_dns
      target_zone_id = module.alb.public_alb_zone_id
    }
  }
}

# Application Load Balancer (ALB)
# The entrypoint for all traffic. Validates SSL and routes traffic to ECS Target Groups.
module "alb" {
  source = "../../modules/alb"

  env                 = var.env
  vpc_id              = module.vpc.vpc_id
  public_subnets      = module.vpc.public_subnets
  alb_sg_id           = module.sg.alb_sg_id
  acm_certificate_arn = module.acm.certificate_arn
  domain_name         = var.domain_name

  # Dev/stage do NOT need internal ALB
  create_internal_alb = false

  frontend_health_check_path = "/"
  backend_health_check_path  = "/health"
  health_check_matcher       = "200-399"

  tags = {
    Environment = var.env
  }
}

# ==============================================================================
# ECS CLUSTER & TASKS
# ==============================================================================

# ECS Cluster
# The logical grouping of tasks and services.
module "ecs_cluster" {
  source = "../../modules/ecs/ecs-cluster"
  env    = var.env

  tags = {
    Environment = var.env
  }
}

# ECS Task Definitions
# Defines the blueprint for containers: Image, CPU/RAM, Environment Variables, Secrets.
module "ecs_task" {
  source = "../../modules/ecs/ecs-task"

  env    = var.env
  region = var.aws_region

  execution_role_arn     = module.iam.ecs_task_execution_role_arn
  task_role_arn_frontend = module.iam.ecs_task_execution_role_arn
  task_role_arn_backend  = module.iam.ecs_backend_task_role_arn # Role with permissions for tasks (e.g. S3 access)

  frontend_image = var.frontend_image
  backend_image  = var.backend_image

  frontend_cpu    = var.frontend_cpu
  frontend_memory = var.frontend_memory
  backend_cpu     = var.backend_cpu
  backend_memory  = var.backend_memory

  backend_readonly_root_filesystem  = var.backend_readonly_root_filesystem
  frontend_readonly_root_filesystem = var.frontend_readonly_root_filesystem

  frontend_container_name = "frontend"
  backend_container_name  = "backend"
  frontend_port           = 80
  backend_port            = 3000
  frontend_log_group_name = "/ecs/${var.env}-frontend"
  backend_log_group_name  = "/ecs/${var.env}-backend"

  backend_tmp_size      = var.backend_tmp_size
  frontend_tmp_size     = var.frontend_tmp_size
  frontend_cache_size   = var.frontend_cache_size
  backend_start_period  = var.backend_start_period
  frontend_start_period = var.frontend_start_period

  ### REQUIRED FOR SECRET INJECTION
  env_secrets_arn = module.secrets.secret_arn

  ### FRONTEND: Only ONE secret key
  frontend_secret_keys = [
    "VITE_API_BASE_URL",
    "MAPTILER_API_KEY",
    "W3W_API_KEY"
  ]

  ### BACKEND: ALL OTHER KEYS
  backend_secret_keys = [
    "APP_JWT_EXPIRATION",
    "APP_JWT_SECRET",
    "AUTH0_ACTION_WEBHOOK_SECRET",
    "AUTH0_AUDIENCE",
    "AUTH0_CALLBACK_URL",
    "AUTH0_CLIENT_ID",
    "AUTH0_CLIENT_SECRET",
    "AUTH0_DOMAIN",
    "AUTH0_ISSUER",
    "AUTH0_LOGOUT_URL",
    "AUTH0_MGMT_CLIENT_ID",
    "BACKEND_PORT",
    "BASE_URL",
    "DB_HOST",
    "DB_NAME",
    "DB_PASS",
    "DB_PORT",
    "DB_USER",
    "SESSION_SECRET",
    "NODE_ENV",
    "POST_LOGIN_REDIRECT_URL",
    "POST_LOGOUT_REDIRECT_URL",
    "ALLOWED_ORIGINS",
    "REDIS_HOST",
    "REDIS_PASSWORD",
    "AWS_REGION",
    "SES_VERIFIED_EMAIL",
    "FRONTEND_URL",
    "W3W_API_KEY",
    "MAPTILER_API_KEY",
    "FARMING_DB_HOST",
    "FARMING_DB_NAME",
    "FARMING_DB_USER",
    "FARMING_DB_PASS",
    "FARMING_DB_PORT"
  ]

  tags = {
    Environment = var.env
  }
}

# AWS Secrets Manager
# Stores sensitive data. ECS tasks pull these values at runtime.
module "secrets" {
  source = "../../modules/secrets"

  project = "rvdevops"
  env     = var.env

  secret_values = {
    APP_JWT_EXPIRATION          = var.APP_JWT_EXPIRATION
    APP_JWT_SECRET              = var.APP_JWT_SECRET
    AUTH0_ACTION_WEBHOOK_SECRET = var.AUTH0_ACTION_WEBHOOK_SECRET
    AUTH0_AUDIENCE              = var.AUTH0_AUDIENCE
    AUTH0_CALLBACK_URL          = var.AUTH0_CALLBACK_URL
    AUTH0_CLIENT_ID             = var.AUTH0_CLIENT_ID
    AUTH0_CLIENT_SECRET         = var.AUTH0_CLIENT_SECRET
    AUTH0_DOMAIN                = var.AUTH0_DOMAIN
    AUTH0_ISSUER                = var.AUTH0_ISSUER
    AUTH0_LOGOUT_URL            = var.AUTH0_LOGOUT_URL
    AUTH0_MGMT_CLIENT_ID        = var.AUTH0_MGMT_CLIENT_ID
    BACKEND_PORT                = var.BACKEND_PORT
    BASE_URL                    = var.BASE_URL
    DB_HOST                     = module.rds.db_address
    DB_NAME                     = var.DB_NAME
    DB_PASS                     = var.DB_PASS
    DB_PORT                     = module.rds.db_port
    DB_USER                     = var.DB_USER
    NODE_ENV                    = var.NODE_ENV
    POST_LOGIN_REDIRECT_URL     = var.POST_LOGIN_REDIRECT_URL
    POST_LOGOUT_REDIRECT_URL    = var.POST_LOGOUT_REDIRECT_URL
    SESSION_SECRET              = var.SESSION_SECRET
    VITE_API_BASE_URL           = var.VITE_API_BASE_URL
    ALLOWED_ORIGINS             = var.ALLOWED_ORIGINS
    REDIS_HOST                  = module.redis.redis_endpoint
    REDIS_PASSWORD              = var.redis_password
    AWS_REGION                  = var.aws_region
    SES_VERIFIED_EMAIL          = var.SES_VERIFIED_EMAIL
    FRONTEND_URL                = var.FRONTEND_URL
    W3W_API_KEY                 = var.W3W_API_KEY
    MAPTILER_API_KEY            = var.MAPTILER_API_KEY
    FARMING_DB_HOST             = module.farming_rds.db_address
    FARMING_DB_NAME             = var.FARMING_DB_NAME
    FARMING_DB_USER             = var.FARMING_DB_USER
    FARMING_DB_PASS             = var.FARMING_DB_PASS
    FARMING_DB_PORT             = var.FARMING_DB_PORT
  }

  tags = {
    Environment = var.env
  }
}

# ECS Services
# Manages the actual running tasks, connects them to Load Balancer, and ensures Desired Count.
module "ecs_service" {
  source = "../../modules/ecs/ecs-service"

  env = var.env

  ecs_cluster_id = module.ecs_cluster.ecs_cluster_id

  frontend_task_definition_arn = module.ecs_task.frontend_task_definition_arn
  backend_task_definition_arn  = module.ecs_task.backend_task_definition_arn

  frontend_tg_arn = module.alb.frontend_tg_arn
  backend_tg_arn  = module.alb.backend_tg_arn

  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets

  frontend_sg_id = module.sg.frontend_ecs_sg_id
  backend_sg_id  = module.sg.backend_ecs_sg_id

  frontend_desired_count = 1
  backend_desired_count  = 1

  frontend_container_name = "frontend"
  backend_container_name  = "backend"
  frontend_container_port = 80
  backend_container_port  = 3000

  tags = {
    Environment = var.env
  }

  # Enable ECS Exec (shell access) for debugging
  enable_execute_command = true

  depends_on = [module.rds]
}

# SSM Parameters for resource sharing
module "ssm" {
  source = "../../modules/ssm"

  env             = var.env
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets

  rds_sg_id    = module.sg.rds_sg_id
  lambda_sg_id = module.sg.lambda_sg_id

  tags = {
    Environment = var.env
  }
}

# ==============================================================================
# DATA STORES
# ==============================================================================

# Redis Cache
# Elasticache instance for caching and session storage.
module "redis" {
  source = "../../modules/redis"

  env                = var.env
  subnet_id          = module.vpc.private_subnets[0] # Put in private subnet for security
  security_group_ids = [module.sg.redis_sg_id]
  instance_type      = var.redis_instance_type
  password           = var.redis_password
  maxmemory          = var.redis_maxmemory
  ami_id             = "ami-0453f2bc6c82c9bb6" # Pinned to prevent constant replacement

  tags = {
    Environment = var.env
  }
}

# RDS Database (PostgreSQL)
# Managed relational database. Publicly accessible for Dev environment easing debugging.
module "rds" {
  source = "../../modules/rds"

  env                 = var.env
  create_rds          = true
  subnet_ids          = module.vpc.public_subnets # Public subnets for Dev DB visibility
  rds_sg_id           = module.sg.rds_sg_id
  publicly_accessible = true

  # Safety: Keep existing naming to avoid DB recreation
  subnet_group_name_override = "${var.env}-rds-subnet-group"

  # Database Configuration 
  database_name   = var.DB_NAME
  database_port   = var.database_port
  master_username = var.DB_USER
  master_password = var.DB_PASS

  # Instance Configuration
  instance_class          = var.instance_class
  allocated_storage       = var.allocated_storage
  backup_retention_period = var.backup_retention_period

  tags = {
    Environment = var.env
  }
}
