# ==============================================================================
# API Gateway Integration Module
# ==============================================================================
# Connects the API Gateway to a backend service.
# - Uses VPC Link to access private resources (Internal ALB).
# - Integration Type: HTTP_PROXY (Pass-through).

resource "aws_apigatewayv2_integration" "backend" {
  api_id                 = var.api_id
  integration_type       = "HTTP_PROXY"
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = var.vpc_link_id
  payload_format_version = "1.0"

  # Integration URI must be the listener ARN of the Internal ALB
  integration_uri = var.internal_alb_listener_arn

  timeout_milliseconds = var.timeout_milliseconds
}
