variable "env" {
  description = "Environment name"
  type        = string
}

variable "dns_zone_name" {
  description = "Name of the Route 53 Hosted Zone"
  type        = string
}

variable "records" {
  description = "Map of DNS records to create (name -> { target_dns, target_zone_id })"
  type = map(object({
    target_dns     = string
    target_zone_id = string
  }))
  default = {}
}
