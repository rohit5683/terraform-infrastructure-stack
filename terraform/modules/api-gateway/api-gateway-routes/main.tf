# ==============================================================================
# API Gateway Routes & Deployment Module
# ==============================================================================
# - Configures Routes: e.g. "ANY /{proxy+}" (Catch-all)
# - Creates Deployment: Activates the configuration.
# - Creates Stage: Represents the lifecycle (e.g. $default).

# Catch-all proxy route
# Forwards everything to the Integration (Backend)
resource "aws_apigatewayv2_route" "proxy" {
  api_id    = var.api_id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${var.integration_id}"
}

# Deployment
# Terraform Resource to trigger updates.
resource "aws_apigatewayv2_deployment" "this" {
  api_id = var.api_id

  # Ensure routes are created before deployment attempts
  depends_on = [aws_apigatewayv2_route.proxy]

  # Force new deployment when critical config changes
  triggers = {
    integration = var.integration_id
  }
}

# Stage
# $default stage enables auto-deployment (changes live immediately).
resource "aws_apigatewayv2_stage" "default" {
  api_id      = var.api_id
  name        = "$default"
  auto_deploy = true
}
