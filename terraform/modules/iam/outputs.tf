output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_backend_task_role_arn" {
  value = aws_iam_role.ecs_backend_task_role.arn
}
