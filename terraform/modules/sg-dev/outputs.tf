output "alb_sg_id" {
  value = aws_security_group.alb_sg.id
}

output "frontend_ecs_sg_id" {
  value = aws_security_group.frontend_ecs_sg.id
}

output "backend_ecs_sg_id" {
  value = aws_security_group.backend_ecs_sg.id
}

output "rds_sg_id" {
  value = aws_security_group.rds_sg.id
}

output "redis_sg_id" {
  value = aws_security_group.redis_sg.id
}

output "lambda_sg_id" {
  value = aws_security_group.lambda_sg.id
}


