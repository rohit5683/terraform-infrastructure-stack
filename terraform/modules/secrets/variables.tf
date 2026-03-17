variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "secret_values" {
  type = map(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}
