# ==============================================================================
# Secrets Manager Module
# ==============================================================================
# Stores all environment variables in a single secure JSON object.
# ECS tasks pull this secret at startup to populate environment variables.

resource "aws_secretsmanager_secret" "this" {
  name                    = "${var.project}/env/${var.env}"
  description             = "Application Environment Credentials"
  recovery_window_in_days = 0 # Force deletion immediately for dev/cleanup
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = jsonencode(var.secret_values)
}
