variable "env" {
  description = "Environment name (e.g. dev, stage, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "Security Group ID for RDS"
  type        = string
}

variable "lambda_sg_id" {
  description = "Security Group ID for Lambda functions"
  type        = string
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}
