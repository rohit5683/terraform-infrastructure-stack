variable "api_id" {
  type = string
}
variable "vpc_link_id" {
  type = string
}
variable "internal_alb_listener_arn" {
  type        = string
  description = "ARN of the internal ALB listener for VPC Link integration"
}
variable "timeout_milliseconds" {
  type    = number
  default = 30000
}
variable "tags" {
  type    = map(string)
  default = {}
}
