# ==============================================================================
# API Gateway VPC Link Module
# ==============================================================================
# Creates a tunnel into the VPC for API Gateway.
# - Allows the Public API Gateway to talk to private ALBs/EC2s.
# - Placed in Private Subnets.

resource "aws_apigatewayv2_vpc_link" "this" {
  name = "${var.env}-vpclink"

  subnet_ids         = var.private_subnets
  security_group_ids = var.apigw_vpclink_sg_id != "" ? [var.apigw_vpclink_sg_id] : []
  tags               = var.tags
}
