variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "secrets_path_arn" {
  description = "The path pattern for secrets this role is allowed to access (relative to secret: prefix)"
  type        = string
  default     = "rvdevops/env/*"
}
