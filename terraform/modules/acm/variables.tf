variable "tags" {
  type    = map(string)
  default = {}
}

variable "env" {
  type = string
}

variable "domain_name" {
  type        = string
  description = "Custom domain name for the certificate (optional)"
  default     = null
}

variable "enable_route53_dns" {
  description = "Whether to create Route 53 records for validation"
  type        = bool
  default     = false
}

variable "zone_id" {
  description = "Zone ID for Route 53 records (required if enable_route53_dns is true)"
  type        = string
  default     = null
}
