variable "env" {
  type = string
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "allowed_origins" {
  description = "List of allowed CORS origins"
  type        = list(string)
  default     = []
}
