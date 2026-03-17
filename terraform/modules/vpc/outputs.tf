output "vpc_id" {
  description = "The ID of VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "This is CIDR block of VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "nat_gateways" {
  value = aws_nat_gateway.this[*].id
}

output "vpc_endpoints_sg_id" {
  value       = var.enable_vpc_endpoints ? aws_security_group.vpc_endpoints_sg[0].id : ""
  description = "Security Group ID used by VPC Interface Endpoints (empty when disabled)"
}
