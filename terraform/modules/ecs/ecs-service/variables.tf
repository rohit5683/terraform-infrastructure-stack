variable "env" { type = string }
variable "tags" { type = map(string) }

variable "ecs_cluster_id" { type = string }

# Task definitions
variable "frontend_task_definition_arn" { type = string }
variable "backend_task_definition_arn" { type = string }

# Load balancer target groups
variable "frontend_tg_arn" { type = string }
variable "backend_tg_arn" { type = string }

# Subnets
variable "public_subnets" { type = list(string) }
variable "private_subnets" { type = list(string) }

# Security Groups
variable "frontend_sg_id" { type = string }
variable "backend_sg_id" { type = string }

# Desired count
variable "frontend_desired_count" {
  type    = number
  default = 1
}

variable "frontend_min_capacity" {
  type    = number
  default = 1
}

variable "frontend_max_capacity" {
  type    = number
  default = 2
}



variable "backend_desired_count" {
  type    = number
  default = 1
}

variable "backend_min_capacity" {
  type    = number
  default = 1
}

variable "backend_max_capacity" {
  type    = number
  default = 2
}

variable "enable_execute_command" {
  type    = bool
  default = false
}

variable "enable_autoscaling" {
  type    = bool
  default = false
}

variable "cpu_target_tracking" {
  type    = number
  default = 70
}

variable "frontend_container_name" {
  type    = string
  default = "frontend"
}

variable "backend_container_name" {
  type    = string
  default = "backend"
}

variable "frontend_container_port" {
  type    = number
  default = 80
}

variable "backend_container_port" {
  type    = number
  default = 3000
}
