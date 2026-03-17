variable "env" {}

variable "domain_name" {}

variable "alb_sg_id" {}

variable "public_subnets" {
  type = list(string)
}

variable "vpc_id" {}

variable "acm_certificate_arn" {}

variable "tags" {
  type = map(string)
}

# Whether to create internal ALB
variable "create_internal_alb" {
  type    = bool
  default = false
}

# Internal ALB values
variable "internal_subnets" {
  type    = list(string)
  default = []
}

variable "internal_alb_sg_id" {
  type    = string
  default = ""
}

variable "internal_cert_arn" {
  type    = string
  default = ""
}

variable "frontend_health_check_path" {
  description = "Path for frontend target group health check"
  type        = string
  default     = "/"
}

variable "backend_health_check_path" {
  description = "Path for backend target group health check"
  type        = string
  default     = "/health"
}

variable "health_check_matcher" {
  description = "HTTP status codes to match for healthy targets"
  type        = string
  default     = "200-399"
}

variable "enable_public_routing_rules" {
  description = "Enable host-based routing rules on public ALB (set to false for Prod/CloudFront)"
  type        = bool
  default     = true
}
