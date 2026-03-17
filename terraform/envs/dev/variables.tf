# AWS region variable
variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
}

variable "env" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

# VPC configuration variables
variable "vpc_cidr" {
  description = "CIDR block for VPC network"
  type        = string
}

variable "azs" {
  description = "Availability Zones for subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}


# Domain name variable
variable "domain_name" {
  description = "Base domain name for the environment (e.g., dev.rvdevops.com)"
  type        = string
}

variable "enable_route53_dns" {
  description = "Whether to use Route 53 for DNS records (false = manual DNS)"
  type        = bool
  default     = false
}

variable "dns_zone_name" {
  description = "The name of the Route 53 hosted zone (e.g. iac.rvdevops.com)"
  type        = string
  default     = null
}




# Application secret variables
variable "APP_JWT_EXPIRATION" {
  description = "JWT token expiration time"
  type        = string
}

variable "APP_JWT_SECRET" {
  description = "Secret key for JWT token signing"
  type        = string
  sensitive   = true
}

variable "AUTH0_ACTION_WEBHOOK_SECRET" {
  description = "Auth0 action webhook secret for verification"
  type        = string
  sensitive   = true
}

variable "AUTH0_AUDIENCE" {
  description = "Auth0 API audience"
  type        = string
}

variable "AUTH0_CALLBACK_URL" {
  description = "Auth0 callback URL"
  type        = string
}

variable "AUTH0_CLIENT_ID" {
  description = "Auth0 application client ID"
  type        = string
}

variable "AUTH0_CLIENT_SECRET" {
  description = "Auth0 application client secret"
  type        = string
  sensitive   = true
}

variable "AUTH0_DOMAIN" {
  description = "Auth0 tenant domain"
  type        = string
}

variable "AUTH0_ISSUER" {
  description = "Auth0 token issuer URL"
  type        = string
}

variable "AUTH0_LOGOUT_URL" {
  description = "Auth0 logout redirect URL"
  type        = string
}

variable "AUTH0_MGMT_CLIENT_ID" {
  description = "Auth0 Management API client ID"
  type        = string
}

variable "BACKEND_PORT" {
  description = "Port number for backend application"
  type        = string
}

variable "BASE_URL" {
  description = "Base URL for the backend API"
  type        = string
}


variable "DB_NAME" {
  description = "Database name"
  type        = string
}

variable "DB_PASS" {
  description = "Database master password"
  type        = string
  sensitive   = true
}


variable "DB_USER" {
  description = "Database master username"
  type        = string
}

variable "FARMING_DB_NAME" {
  description = "Farming practices database name"
  type        = string
}

variable "FARMING_DB_PASS" {
  description = "Farming practices database master password"
  type        = string
  sensitive   = true
}

variable "FARMING_DB_USER" {
  description = "Farming practices database master username"
  type        = string
}

variable "FARMING_DB_PORT" {
  description = "Farming practices database port number"
  type        = number
  default     = 5432
}

variable "NODE_ENV" {
  description = "Node.js environment (development, production)"
  type        = string
}

variable "POST_LOGIN_REDIRECT_URL" {
  description = "URL to redirect after successful login"
  type        = string
}

variable "POST_LOGOUT_REDIRECT_URL" {
  description = "URL to redirect after logout"
  type        = string
}

variable "SESSION_SECRET" {
  description = "Secret key for session encryption"
  type        = string
  sensitive   = true
}

variable "VITE_API_BASE_URL" {
  description = "API base URL for frontend Vite application"
  type        = string
}

variable "ALLOWED_ORIGINS" {
  description = "Comma-separated list of allowed CORS origins"
  type        = string
}



variable "SES_VERIFIED_EMAIL" {
  description = "Verified email address for AWS SES"
  type        = string
}

variable "FRONTEND_URL" {
  description = "Frontend application URL"
  type        = string
}

variable "W3W_API_KEY" {
  description = "What3Words API key"
  type        = string
  sensitive   = true
}

variable "MAPTILER_API_KEY" {
  description = "MapTiler API key"
  type        = string
  sensitive   = true
}


# ECS Task variables
variable "frontend_cpu" {
  description = "CPU units for frontend ECS task (256 = 0.25 vCPU)"
  type        = number
}

variable "frontend_memory" {
  description = "Memory (MB) for frontend ECS task"
  type        = number
}

variable "backend_cpu" {
  description = "CPU units for backend ECS task (512 = 0.5 vCPU)"
  type        = number
}

variable "backend_memory" {
  description = "Memory (MB) for backend ECS task"
  type        = number
}


variable "frontend_image" {
  description = "Docker image URI for frontend application"
  type        = string
}

variable "backend_image" {
  description = "Docker image URI for backend application"
  type        = string
}

variable "frontend_desired_count" {
  description = "Desired number of frontend ECS tasks"
  type        = number
  default     = 1
}

variable "frontend_min_capacity" {
  description = "Minimum number of frontend ECS tasks for autoscaling"
  type        = number
  default     = 1
}

variable "frontend_max_capacity" {
  description = "Maximum number of frontend ECS tasks for autoscaling"
  type        = number
  default     = 2
}

variable "backend_desired_count" {
  description = "Desired number of backend ECS tasks"
  type        = number
  default     = 1
}

variable "backend_min_capacity" {
  description = "Minimum number of backend ECS tasks for autoscaling"
  type        = number
  default     = 1
}

variable "backend_max_capacity" {
  description = "Maximum number of backend ECS tasks for autoscaling"
  type        = number
  default     = 2
}

variable "redis_instance_type" {
  description = "Instance type for Redis"
  type        = string
  default     = "t3.micro"
}

variable "redis_password" {
  description = "Redis password"
  type        = string
  sensitive   = true
}

variable "redis_maxmemory" {
  description = "Redis maxmemory setting"
  type        = string
  default     = "256mb"
}

variable "database_port" {
  description = "Database port number"
  type        = number
  default     = 5432
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "RDS allocated storage in GB"
  type        = number
  default     = 20
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "backend_readonly_root_filesystem" {
  description = "Enable readonly root filesystem for the backend"
  type        = bool
  default     = false
}

variable "frontend_readonly_root_filesystem" {
  description = "Enable readonly root filesystem for the frontend"
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
