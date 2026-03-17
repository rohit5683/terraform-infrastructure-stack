# ==============================================================================
# API Gateway HTTP API Module
# ==============================================================================
# Creates the API Gateway V2 (HTTP API) resource.
# - Lighter, faster, and cheaper than REST APIs.
# - Includes CORS configuration for the frontend domain.

resource "aws_apigatewayv2_api" "this" {
  name          = "${var.env}-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins     = var.allowed_origins
    allow_methods     = ["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"]
    allow_headers     = ["content-type", "authorization", "x-requested-with", "accept", "origin", "x-tenant-id"]
    expose_headers    = ["content-length", "content-type"]
    max_age           = 3600
    allow_credentials = true
  }

  tags = var.tags
}
