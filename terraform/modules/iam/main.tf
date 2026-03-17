# ==============================================================================
# IAM Roles Module
# ==============================================================================
# Defines Identity and Access Management roles for ECS.
# - ECS Execution Role: Helper role for ECS Agent (Pull images, logs, secrets)
# - ECS Task Role: The role the *App Code* uses (Access S3, etc.)

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# 1. ECS Task Execution Role (The "Agent" Role)
# Used by the ECS container agent (not the code itself)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.env}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Attach Managed Policies
# - AmazonECSTaskExecutionRolePolicy: Standard permissions (logs, ecr pull)
# - AmazonSSMManagedInstanceCore: Allows ECS Exec (Shell Access)
resource "aws_iam_role_policy_attachment" "ecs_execution_managed" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_execution_ssm" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Custom Policy: Secrets Manager Access
# Allows the ECS Agent to inject environment variables from Secrets Manager at startup.
resource "aws_iam_policy" "secrets_access_policy" {
  name        = "${var.env}-ecsSecretsPolicy"
  description = "Policy to allow ECS tasks to access specific Secrets Manager secrets"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.secrets_path_arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access_policy.arn
}


# 2. ECS Task Role (The "App" Role)
# Used by your application code (NestJS) to call AWS SDKs (e.g. upload to S3)
resource "aws_iam_role" "ecs_backend_task_role" {
  name = "${var.env}-ecsBackendTaskRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# Backend App Permissions
# - S3 Full Access (image uploads)
# - CloudWatch Logs (logging)
# - Secrets Manager Read/Write (if app manages secrets)
resource "aws_iam_role_policy_attachment" "backend_s3" {
  role       = aws_iam_role.ecs_backend_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "backend_ssm_core" {
  role       = aws_iam_role.ecs_backend_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "backend_ssm_readonly" {
  role       = aws_iam_role.ecs_backend_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "backend_cloudwatch" {
  role       = aws_iam_role.ecs_backend_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "backend_secrets" {
  role       = aws_iam_role.ecs_backend_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# Custom Policy: SES Email Sending
resource "aws_iam_policy" "backend_ses_policy" {
  name        = "${var.env}-ecsBackendSESPolicy"
  description = "Allows backend ECS tasks to send emails via SES"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backend_ses_attach" {
  role       = aws_iam_role.ecs_backend_task_role.name
  policy_arn = aws_iam_policy.backend_ses_policy.arn
}
