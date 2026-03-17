# VPC Outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}


# IAM Outputs
output "ecs_task_execution_role_arn" {
  value = module.iam.ecs_task_execution_role_arn
}

output "ecs_backend_task_role_arn" {
  value = module.iam.ecs_backend_task_role_arn
}


# SG Outputs
output "alb_sg_id" {
  value = module.sg.frontend_alb_sg_id
}

output "frontend_ecs_sg_id" {
  value = module.sg.frontend_ecs_sg_id
}

output "backend_ecs_sg_id" {
  value = module.sg.backend_ecs_sg_id
}

output "rds_sg_id" {
  value = module.sg.rds_sg_id
}

# ACM Outputs
output "acm_certificate_arn" {
  value = module.acm.certificate_arn
}

output "acm_validation_records" {
  value = module.acm.validation_records
}

# ALB Outputs
output "public_alb_dns" {
  value = module.alb.public_alb_dns
}

output "public_alb_arn" {
  value = module.alb.public_alb_arn
}

output "frontend_tg" {
  value = module.alb.frontend_tg_arn
}

output "backend_tg" {
  value = module.alb.backend_tg_arn
}



output "rds_endpoint" {
  value = module.rds.db_endpoint
}

output "rds_address" {
  value = module.rds.db_address
}
