# ==============================================================================
# ECS Task Definition Module
# ==============================================================================
# Defines the "Blueprint" for containers:
# - Docker Image URL
# - CPU / Memory
# - Port Mappings
# - Environment Variables & Secrets
# - Logging Configuration

# ------------------------------------------------------------------------------
# CloudWatch Log Groups
# ------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "frontend_ecs_sg_id" {
  name              = var.frontend_log_group_name != null ? var.frontend_log_group_name : "/ecs/${var.env}-frontend"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "backend" {
  name              = var.backend_log_group_name != null ? var.backend_log_group_name : "/ecs/${var.env}-backend"
  retention_in_days = 7

  tags = var.tags
}


# ------------------------------------------------------------------------------
# FRONTEND Task Definition
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${var.env}-frontend"
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  network_mode             = "awsvpc" # Required for Fargate
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = var.execution_role_arn     # For ECS Agent (Pull images)
  task_role_arn      = var.task_role_arn_frontend # For App Code

  container_definitions = jsonencode([
    {
      name                   = var.frontend_container_name
      image                  = var.frontend_image
      essential              = true
      readonlyRootFilesystem = var.frontend_readonly_root_filesystem

      portMappings = [
        {
          containerPort = var.frontend_port
          hostPort      = var.frontend_port
          protocol      = "tcp"
        }
      ]

      # Writable tmpfs mounts required for hardened containers
      # Following user blueprint: /tmp (128Mi), /var/cache/nginx (128Mi), /var/run (4Mi), /etc/nginx/conf.d (16Mi), /var/lib/nginx (64Mi)
      linuxParameters = var.frontend_readonly_root_filesystem ? {
        tmpfs = [
          { containerPath = "/tmp", size = var.frontend_tmp_size },
          { containerPath = "/var/cache/nginx", size = var.frontend_cache_size },
          { containerPath = "/var/run", size = 4 },
          { containerPath = "/etc/nginx/conf.d", size = 16 },
          { containerPath = "/var/lib/nginx", size = 64 },
          { containerPath = "/var/lib/amazon/ssm", size = 16 },
          { containerPath = "/var/log/amazon/ssm", size = 16 }
        ]
      } : null

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.frontend_port}/ || exit 1"]
        interval    = 30
        retries     = 3
        startPeriod = var.frontend_start_period
        timeout     = 5
      }

      # Secrets Injection
      # Pulls values from Secrets Manager and sets them as Env Vars
      secrets = [
        for key in var.frontend_secret_keys : {
          name      = key
          valueFrom = "${var.env_secrets_arn}:${key}::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend_ecs_sg_id.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}


# ------------------------------------------------------------------------------
# BACKEND Task Definition
# ------------------------------------------------------------------------------
resource "aws_ecs_task_definition" "backend" {
  family                   = "${var.env}-backend"
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = var.execution_role_arn
  task_role_arn      = var.task_role_arn_backend

  container_definitions = jsonencode([
    {
      name                   = var.backend_container_name
      image                  = var.backend_image
      essential              = true
      readonlyRootFilesystem = var.backend_readonly_root_filesystem

      portMappings = [
        {
          containerPort = var.backend_port
          hostPort      = var.backend_port
          protocol      = "tcp"
        }
      ]

      # Writable tmpfs mount for temporary file operations.
      # Increased to 256Mi to accommodate application writes (PM2 metadata) redirected to /tmp via symlinks.
      linuxParameters = var.backend_readonly_root_filesystem ? {
        tmpfs = [
          { containerPath = "/tmp", size = var.backend_tmp_size },
          { containerPath = "/var/lib/amazon/ssm", size = 16 },
          { containerPath = "/var/log/amazon/ssm", size = 16 }
        ]
      } : null

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${var.backend_port}/health || exit 1"]
        interval    = 30
        retries     = 3
        startPeriod = var.backend_start_period
        timeout     = 5
      }

      # Environment Variables
      environment = concat(var.backend_env_vars, [
        { name = "PM2_HOME", value = "/tmp/.pm2" }
      ])

      # Secrets Injection
      secrets = [
        for key in var.backend_secret_keys : {
          name      = key
          valueFrom = "${var.env_secrets_arn}:${key}::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.region
          awslogs-group         = aws_cloudwatch_log_group.backend.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  tags = var.tags
}
