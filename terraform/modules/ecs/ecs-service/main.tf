# ==============================================================================
# ECS Service Module
# ==============================================================================
# Manages the lifecycle of running tasks.
# - Ensures 'desired_count' of tasks are running.
# - Registers tasks with the Application Load Balancer (ALB).
# - Handles replacement of failed tasks (Self Healing).

# ------------------------------------------------------------------------------
# FRONTEND ECS SERVICE
# ------------------------------------------------------------------------------
resource "aws_ecs_service" "frontend" {
  name            = "${var.env}-frontend-service"
  cluster         = var.ecs_cluster_id
  task_definition = var.frontend_task_definition_arn
  launch_type     = "FARGATE"
  desired_count   = var.frontend_desired_count

  network_configuration {
    subnets          = var.public_subnets # Public subnets for direct internet access (e.g. pulling images)
    security_groups  = [var.frontend_sg_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.frontend_tg_arn
    container_name   = var.frontend_container_name
    container_port   = var.frontend_container_port
  }

  propagate_tags = "SERVICE"

  tags = var.tags

  # Prevent Terraform from resetting Desired Count if Autoscaling changes it
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  enable_execute_command = var.enable_execute_command
}


# ------------------------------------------------------------------------------
# BACKEND ECS SERVICE
# ------------------------------------------------------------------------------
resource "aws_ecs_service" "backend" {
  name            = "${var.env}-backend-service"
  cluster         = var.ecs_cluster_id
  task_definition = var.backend_task_definition_arn
  launch_type     = "FARGATE"
  desired_count   = var.backend_desired_count

  network_configuration {
    subnets          = var.private_subnets # Private subnets for security
    security_groups  = [var.backend_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_tg_arn
    container_name   = var.backend_container_name
    container_port   = var.backend_container_port
  }

  propagate_tags = "SERVICE"

  tags = var.tags

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }

  enable_execute_command = var.enable_execute_command
}


# ==============================================================================
# AUTO SCALING (FrontEnd)
# ==============================================================================

resource "aws_appautoscaling_target" "frontend_target" {
  count              = var.enable_autoscaling ? 1 : 0
  max_capacity       = var.frontend_max_capacity
  min_capacity       = var.frontend_min_capacity
  resource_id        = "service/${element(split("/", var.ecs_cluster_id), length(split("/", var.ecs_cluster_id)) - 1)}/${aws_ecs_service.frontend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "frontend_cpu_policy" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.env}-frontend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.frontend_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_tracking
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# ==============================================================================
# AUTO SCALING (BackEnd)
# ==============================================================================

resource "aws_appautoscaling_target" "backend_target" {
  count              = var.enable_autoscaling ? 1 : 0
  max_capacity       = var.backend_max_capacity
  min_capacity       = var.backend_min_capacity
  resource_id        = "service/${element(split("/", var.ecs_cluster_id), length(split("/", var.ecs_cluster_id)) - 1)}/${aws_ecs_service.backend.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "backend_cpu_policy" {
  count              = var.enable_autoscaling ? 1 : 0
  name               = "${var.env}-backend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.backend_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.backend_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.backend_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_tracking
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
