variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "task_role_arn_frontend" {
  type = string
}

variable "task_role_arn_backend" {
  type = string
}

variable "frontend_image" {
  type        = string
  description = "Frontend Docker image (ECR URL)"
}

variable "backend_image" {
  type        = string
  description = "Backend Docker image (ECR URL)"
}

variable "frontend_cpu" {
  type    = number
  default = 256
}

variable "frontend_memory" {
  type    = number
  default = 512
}

variable "backend_cpu" {
  type    = number
  default = 512
}

variable "backend_memory" {
  type    = number
  default = 1024
}

variable "backend_env_vars" {
  type    = list(object({ name = string, value = string }))
  default = []
}

variable "backend_secret_arns" {
  type    = map(string)
  default = {}
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "frontend_secret_keys" {
  type    = list(string)
  default = []
}

variable "backend_secret_keys" {
  type    = list(string)
  default = []
}

variable "env_secrets_arn" {
  type = string
}

variable "frontend_container_name" {
  type    = string
  default = "frontend"
}

variable "backend_container_name" {
  type    = string
  default = "backend"
}

variable "frontend_port" {
  type    = number
  default = 80
}

variable "backend_port" {
  type    = number
  default = 3000
}

variable "frontend_log_group_name" {
  type    = string
  default = null
}

variable "backend_log_group_name" {
  type    = string
  default = null
}

variable "backend_readonly_root_filesystem" {
  description = "Mount the backend container's root filesystem as read-only"
  type        = bool
  default     = false
}

variable "frontend_readonly_root_filesystem" {
  description = "Mount the frontend container's root filesystem as read-only"
  type        = bool
  default     = false
}

variable "backend_tmp_size" {
  description = "Size of the /tmp mount for the backend container in MiB"
  type        = number
  default     = 256
}

variable "frontend_tmp_size" {
  description = "Size of the /tmp mount for the frontend container in MiB"
  type        = number
  default     = 128
}

variable "frontend_cache_size" {
  description = "Size of the /var/cache/nginx mount for the frontend container in MiB"
  type        = number
  default     = 128
}


variable "backend_start_period" {
  description = "Health check start period for backend container in seconds"
  type        = number
  default     = 120
}

variable "frontend_start_period" {
  description = "Health check start period for frontend container in seconds"
  type        = number
  default     = 60
}
