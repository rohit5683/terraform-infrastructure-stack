#################################
# VPC Outputs
#################################
output "vpc_id" {
  value = module.vpc.vpc_id
}


#################################
# IAM Outputs
#################################
output "ecs_task_execution_role_arn" {
  value = module.iam.ecs_task_execution_role_arn
}

output "ecs_backend_task_role_arn" {
  value = module.iam.ecs_backend_task_role_arn
}


#################################
# SECURITY GROUP OUTPUTS (PROD)
#################################

# Public ALB Security Group (Frontend ALB)
output "frontend_alb_sg_id" {
  value = module.sg.frontend_alb_sg_id
}

# Private ALB Security Group (Backend ALB)
output "backend_alb_sg_id" {
  value = module.sg.backend_alb_sg_id
}

# ECS Security Groups
output "frontend_ecs_sg_id" {
  value = module.sg.frontend_ecs_sg_id
}

output "backend_ecs_sg_id" {
  value = module.sg.backend_ecs_sg_id
}

# RDS Security Group
output "rds_sg_id" {
  value = module.sg.rds_sg_id
}

# API Gateway VPC Link SG
output "apigw_vpclink_sg_id" {
  value = module.sg.apigw_vpclink_sg_id
}

# Jump/SSM EC2 SG
output "jump_ssm_sg_id" {
  value = module.sg.jump_ssm_sg_id
}


#################################
# ACM Outputs
#################################
output "acm_certificate_arn" {
  value = module.acm.certificate_arn
}

output "acm_validation_records" {
  value = module.acm.validation_records
}


#################################
# ALB Outputs
#################################
output "public_alb_dns" {
  value = module.alb.public_alb_dns
}

output "public_alb_arn" {
  value = module.alb.public_alb_arn
}

output "internal_alb_dns" {
  value = module.alb.internal_alb_dns
}

output "internal_alb_arn" {
  value = module.alb.internal_alb_arn
}

output "frontend_tg" {
  value = module.alb.frontend_tg_arn
}

output "backend_tg" {
  value = module.alb.backend_tg_arn
}

#################################
# CloudFront Outputs
#################################
output "cloudfront_distribution_id" {
  value       = module.cloudfront.distribution_id
  description = "CloudFront distribution ID"
}

output "cloudfront_domain_name" {
  value       = module.cloudfront.distribution_domain_name
  description = "CloudFront domain name - Create CNAME: app.prod.iac.rvdevops.com -> this value"
}

output "cloudfront_distribution_arn" {
  value = module.cloudfront.distribution_arn
}

#################################
# API GATEWAY OUTPUTS
#################################
output "api_gateway_url" {
  value = module.http_api.api_endpoint
}

output "api_custom_domain_target" {
  value = module.api_custom_domain.api_gateway_target_domain
}

#################################
# RDS Outputs
#################################
output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_endpoint
}

output "rds_address" {
  description = "RDS instance hostname"
  value       = module.rds.db_address
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.db_port
}

output "rds_database_name" {
  description = "Name of the database"
  value       = module.rds.db_name
}

output "redis_endpoint" {
  value = module.redis.redis_endpoint
}
