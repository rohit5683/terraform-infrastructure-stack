output "db_instance_id" {
  description = "ID of the RDS instance"
  value       = var.create_rds ? aws_db_instance.this[0].id : null
}

output "db_instance_arn" {
  description = "ARN of the RDS instance"
  value       = var.create_rds ? aws_db_instance.this[0].arn : null
}

output "db_endpoint" {
  description = "Connection endpoint for the database"
  value       = var.create_rds ? aws_db_instance.this[0].endpoint : null
}

output "db_address" {
  description = "Hostname of the RDS instance"
  value       = var.create_rds ? aws_db_instance.this[0].address : null
}

output "db_port" {
  description = "Port of the RDS instance"
  value       = var.create_rds ? aws_db_instance.this[0].port : null
}

output "db_name" {
  description = "Name of the database"
  value       = var.create_rds ? aws_db_instance.this[0].db_name : null
}

output "db_username" {
  description = "Master username for the database"
  value       = var.create_rds ? aws_db_instance.this[0].username : null
  sensitive   = true
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = var.create_rds ? aws_db_subnet_group.this[0].name : null
}
