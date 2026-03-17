variable "env" {
  description = "Environment name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in"
  type        = string
}

variable "security_group_ids" {
  description = "List of Security Group IDs"
  type        = list(string)
  default     = []
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "password" {
  description = "Redis password"
  type        = string
  sensitive   = true
}

variable "maxmemory" {
  description = "Redis maxmemory setting"
  type        = string
  default     = "256mb"
}


variable "ami_id" {
  description = "Specific AMI ID to use. If null, uses latest Amazon Linux 2023."
  type        = string
  default     = null
}
