variable "name" {
  description = "Name of the VPC"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the VPC"
  type        = map(string)
  default     = {}
}

variable "azs" {
  description = "Availability zones to use"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "enable_vpc_endpoints" {
  type        = bool
  description = "Enable VPC Interface Endpoints (SSM) — set true only for prod"
  default     = false
}

variable "vpc_interface_endpoints" {
  description = "List of VPC Interface Endpoints to create (e.g., ssm, ec2messages)"
  type        = list(string)
  default     = []
}
