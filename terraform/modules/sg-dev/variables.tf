variable "env" {
  type = string
}


variable "vpc_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "rds_public_access" {
  type        = bool
  description = "Enable public access to RDS SG"
  default     = false
}
