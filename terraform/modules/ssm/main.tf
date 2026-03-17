resource "aws_ssm_parameter" "vpc_id" {
  name  = "/rvdevops/${var.env}/vpc/id"
  type  = "String"
  value = var.vpc_id
  tags  = var.tags
}

resource "aws_ssm_parameter" "public_subnets" {
  name  = "/rvdevops/${var.env}/vpc/public_subnets"
  type  = "StringList"
  value = join(",", var.public_subnets)
  tags  = var.tags
}

resource "aws_ssm_parameter" "private_subnets" {
  name  = "/rvdevops/${var.env}/vpc/private_subnets"
  type  = "StringList"
  value = join(",", var.private_subnets)
  tags  = var.tags
}

resource "aws_ssm_parameter" "rds_sg_id" {
  name  = "/rvdevops/${var.env}/sg/rds_id"
  type  = "String"
  value = var.rds_sg_id
  tags  = var.tags
}

resource "aws_ssm_parameter" "lambda_sg_id" {
  name  = "/rvdevops/${var.env}/sg/lambda_id"
  type  = "String"
  value = var.lambda_sg_id
  tags  = var.tags
}
