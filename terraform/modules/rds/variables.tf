variable "env" {
  type        = string
  description = "Environment name (e.g., prod, stage, dev)"
}

variable "create_rds" {
  type        = bool
  description = "Whether to create RDS database or not"
  default     = false
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for RDS subnet group"
}

variable "publicly_accessible" {
  type        = bool
  description = "Whether the DB should be publicly accessible"
  default     = false
}

variable "rds_sg_id" {
  type        = string
  description = "Security group ID for RDS"
}

variable "name" {
  type        = string
  description = "The name for this RDS instance and its groups (e.g. primary, farming)"
  default     = "postgres"
}

variable "subnet_group_name_override" {
  type        = string
  description = "Override the default subnet group name (for legacy support)"
  default     = null
}

# Database Configuration
variable "database_name" {
  type        = string
  description = "Name of the database to create"
  default     = "appdb"
}

variable "database_port" {
  type        = number
  description = "Port for the database"
  default     = 5432
}

variable "master_username" {
  type        = string
  description = "Master username for the database"
}

variable "master_password" {
  type        = string
  description = "Master password for the database"
  sensitive   = true
}


# Instance Configuration
variable "instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro" # Free tier eligible
}

variable "allocated_storage" {
  type        = number
  description = "Allocated storage in GB"
  default     = 20
}

variable "storage_type" {
  type        = string
  description = "Storage type (gp2, gp3, io1)"
  default     = "gp3"
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL engine version"
  default     = "15.10" # Latest stable AWS RDS version
}


variable "parameter_group_family" {
  type        = string
  description = "PostgreSQL parameter group family"
  default     = "postgres15"
}

# Deletion Protection
variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection"
  default     = true
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on deletion (not recommended for production)"
  default     = false
}

# Performance Insights
variable "enable_performance_insights" {
  type        = bool
  description = "Enable Performance Insights"
  default     = false
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to resources"
}

variable "backup_retention_period" {
  type        = number
  description = "The days to retain backups for"
  default     = 7
}

variable "apply_immediately" {
  type        = bool
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  default     = false
}
