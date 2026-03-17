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
  app_domain = var.domain_name
  api_domain = "api.rvdevops.com"
}

# ==============================================================================
# NETWORK & INFRASTRUCTURE
# ==============================================================================

# Virtual Private Cloud (VPC)
# Production network with VPC Endpoints enabled for security (traffic stays in AWS network).
module "vpc" {
  source               = "../../modules/vpc"
  name                 = "${var.env}-vpc"
  cidr_block           = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  region               = var.aws_region # REQUIRED for endpoints
  enable_vpc_endpoints = true           # ENABLE in PROD for security/performance
  vpc_interface_endpoints = [
    "com.amazonaws.${var.aws_region}.ssm",
    "com.amazonaws.${var.aws_region}.ssmmessages",
    "com.amazonaws.${var.aws_region}.ec2messages"
  ]

  tags = {
    Environment = var.env
  }
}

# IAM Roles
# Production execution roles.
module "iam" {
  source           = "../../modules/iam"
  env              = var.env
  region           = var.aws_region
  secrets_path_arn = "rvdevops/env/*"
}

# Security Groups
# Production-specific SGs (may differ from dev-stage).
module "sg" {
  source              = "../../modules/sg-stage-prod"
  env                 = var.env
  vpc_id              = module.vpc.vpc_id
  vpc_endpoints_sg_id = module.vpc.vpc_endpoints_sg_id
  tags = {
    Environment = var.env
  }
}

# ==============================================================================
# DOMAIN & EDGE DELIVERY
# ==============================================================================

# ACM Certificate (CloudFront)
# SSL Certificate for CloudFront distribution (must be in us-east-1).
module "acm" {
  source = "../../modules/acm"
  env    = var.env

  # Pass the custom domain to the module (or null for default wildcard)
  domain_name = var.certificate_domain

  tags = {
    Environment = var.env
  }

  enable_route53_dns = var.enable_route53_dns
  zone_id            = var.enable_route53_dns ? module.route53[0].zone_id : null
}

# DNS Records (Route53)
# Routes traffic to CloudFront (App) and API Gateway (API).
module "route53" {
  source = "../../modules/route53"
  count  = var.enable_route53_dns ? 1 : 0

  env           = var.env
  dns_zone_name = var.dns_zone_name

  records = {
    (local.app_domain) = {
      target_dns     = module.cloudfront.distribution_domain_name
      target_zone_id = "Z2FDTNDATAQYW2" # CloudFront hosted zone ID (global)
    }
    "www.${local.app_domain}" = {
      target_dns     = module.cloudfront.distribution_domain_name
      target_zone_id = "Z2FDTNDATAQYW2" # CloudFront hosted zone ID (global)
    }
    (local.api_domain) = {
      target_dns     = module.api_custom_domain.api_gateway_target_domain
      target_zone_id = module.api_custom_domain.api_gateway_hosted_zone_id
    }
  }
}

# Application Load Balancer
# Handles both Public traffic and Internal traffic (via Internal ALB for API Gateway).
module "alb" {
  source = "../../modules/alb"

  env                 = var.env
  vpc_id              = module.vpc.vpc_id
  public_subnets      = module.vpc.public_subnets
  alb_sg_id           = module.sg.frontend_alb_sg_id
  acm_certificate_arn = module.acm.certificate_arn
  domain_name         = var.domain_name

  # Internal ALB enabled for API Gateway integration
  create_internal_alb = true

  enable_public_routing_rules = false

  frontend_health_check_path = "/"
  backend_health_check_path  = "/health"
  health_check_matcher       = "200-399"

  internal_subnets   = module.vpc.private_subnets
  internal_alb_sg_id = module.sg.backend_alb_sg_id

  tags = {
    Environment = var.env
  }
}

# CloudFront Distribution
# Global CDN for the Frontend SPA, caching static assets.
module "cloudfront" {
  source = "../../modules/cloudfront"

  env             = var.env
  domain_name     = var.domain_name
  alb_dns_name    = module.alb.public_alb_dns
  certificate_arn = module.acm.cloudfront_certificate_arn

  tags = {
    Environment = var.env
  }
}

# ==============================================================================
# API GATEWAY (Advanced Routing)
# ==============================================================================

# VPC Link
# Allows API Gateway HTTP API to talk to private resources (Internal ALB) in VPC.
module "vpclink" {
  source = "../../modules/api-gateway/api-gateway-vpclink"

  env                 = var.env
  private_subnets     = module.vpc.private_subnets
  apigw_vpclink_sg_id = module.sg.apigw_vpclink_sg_id

  tags = { Environment = var.env }
}

# HTTP API
# The modern, low-cost API Gateway.
module "http_api" {
  source = "../../modules/api-gateway/api-gateway-http-api"

  env             = var.env
  allowed_origins = ["https://app.rvdevops.com", "https://www.app.rvdevops.com"]
  tags            = { Environment = var.env }
}

# Integration
# Connects API Routes to the VPC Link -> Internal ALB.
module "api_integration" {
  source = "../../modules/api-gateway/api-gateway-integration"

  api_id                    = module.http_api.api_id
  vpc_link_id               = module.vpclink.vpc_link_id
  internal_alb_listener_arn = module.alb.internal_listener_arn

  tags = { Environment = var.env }
}

# Routes & Stages
# Defines the API path structure and deployment stages.
module "api_routes" {
  source = "../../modules/api-gateway/api-gateway-routes"

  api_id         = module.http_api.api_id
  integration_id = module.api_integration.integration_id
}

# API Custom Domain
# Maps 'api.prod...' to the API Gateway.
module "api_custom_domain" {
  source = "../../modules/api-gateway/api-custom-domain"

  domain_name     = "api.rvdevops.com"
  certificate_arn = module.acm.certificate_arn # Reuse existing wildcard cert
  api_id          = module.http_api.api_id
  stage_name      = module.api_routes.stage_name # Ensures stage is created first

  tags = { Environment = var.env }
}

# ==============================================================================
# ECS CLUSTER & TASKS
# ==============================================================================

module "ecs_cluster" {
  source = "../../modules/ecs/ecs-cluster"
  env    = var.env

  tags = {
    Environment = var.env
  }
}

module "ecs_task" {
  source = "../../modules/ecs/ecs-task"

  env    = var.env
  region = var.aws_region

  execution_role_arn     = module.iam.ecs_task_execution_role_arn
  task_role_arn_frontend = module.iam.ecs_task_execution_role_arn
  task_role_arn_backend  = module.iam.ecs_backend_task_role_arn

  frontend_image = var.frontend_image
  backend_image  = var.backend_image

  frontend_cpu    = var.frontend_cpu
  frontend_memory = var.frontend_memory
  backend_cpu     = var.backend_cpu
  backend_memory  = var.backend_memory

  frontend_readonly_root_filesystem = var.frontend_readonly_root_filesystem
  backend_readonly_root_filesystem  = var.backend_readonly_root_filesystem

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
    "MAPTILER_API_KEY"
  ]

  tags = {
    Environment = var.env
  }
}

# AWS Secrets Manager
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
  }

  tags = {
    Environment = var.env
  }
}

# ECS Service
# Production services, scalable, with ECS Exec enabled.
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

  frontend_desired_count = var.frontend_desired_count
  frontend_min_capacity  = var.frontend_min_capacity
  frontend_max_capacity  = var.frontend_max_capacity

  backend_desired_count = var.backend_desired_count
  backend_min_capacity  = var.backend_min_capacity
  backend_max_capacity  = var.backend_max_capacity

  frontend_container_name = "frontend"
  backend_container_name  = "backend"
  frontend_container_port = 80
  backend_container_port  = 3000

  enable_autoscaling  = true
  cpu_target_tracking = var.cpu_target_tracking

  tags = {
    Environment = var.env
  }

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

module "redis" {
  source = "../../modules/redis"

  env       = var.env
  subnet_id = module.vpc.private_subnets[0]
  security_group_ids = [
    module.sg.redis_sg_id,
    module.sg.jump_ssm_sg_id
  ]
  instance_type = var.redis_instance_type
  password      = var.redis_password
  maxmemory     = var.redis_maxmemory
  ami_id        = "ami-0453f2bc6c82c9bb6" # Pinned

  tags = {
    Environment = var.env
  }
}

# RDS Database (PostgreSQL)
# Production database.
module "rds" {
  source = "../../modules/rds"

  env        = var.env
  create_rds = true
  subnet_ids = module.vpc.private_subnets
  rds_sg_id  = module.sg.rds_sg_id

  # Safety: Keep existing naming to avoid DB recreation
  subnet_group_name_override = "${var.env}-rds-subnet-group"

  # Database Configuration
  database_name   = var.DB_NAME
  database_port   = var.DB_PORT
  master_username = var.DB_USER
  master_password = var.DB_PASS

  # Instance Configuration
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  # engine_version          = "15.10"
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  backup_retention_period = var.backup_retention_period
  apply_immediately       = true

  tags = {
    Environment = var.env
  }
}

