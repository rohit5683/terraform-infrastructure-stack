# ==============================================================================
# VPC Module (Standard 3-Tier Network)
# ==============================================================================
# Creates:
# - Helper resources (Internet Gateway, NAT Gateway, Routing Tables)
# - Public Subnets (for ALB, NAT) - Internet accessible
# - Private Subnets (for ECS, RDS, Redis) - No direct internet access
# - Conditional VPC Endpoints (for secure AWS service access)

# Create VPC
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = var.name
  })
}

# Internet Gateway
# Allows traffic from Public Subnets to reach the internet.
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = element(var.azs, count.index)

  tags = merge(var.tags, {
    Name = "${var.name}-public-${count.index}"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count                   = length(var.private_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = element(var.azs, count.index)

  tags = merge(var.tags, {
    Name = "${var.name}-private-${count.index}"
  })
}

# Elastic IP for NAT Gateway
# Static IP required for the NAT Gateway to function.
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip"
  })
}

# NAT Gateway
# Allows Private Subnets to make outbound requests (e.g. download Docker images)
# but prevents inbound connections from the internet.
resource "aws_nat_gateway" "this" {
  subnet_id     = element(aws_subnet.public[*].id, 0)
  allocation_id = aws_eip.nat.id

  tags = merge(var.tags, {
    Name = "${var.name}-nat"
  })
}

# Public Route Table
# Route 0.0.0.0/0 -> Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table
# Route 0.0.0.0/0 -> NAT Gateway
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt"
  })
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}


# ==============================================================================
# VPC ENDPOINTS (Optional)
# ==============================================================================
# Security Group for Interface Endpoints
resource "aws_security_group" "vpc_endpoints_sg" {
  count       = var.enable_vpc_endpoints ? 1 : 0
  name        = "${var.name}-vpc-endpoints-sg"
  description = "Security group for VPC interface endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "Allow HTTPS from VPC subnets"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-vpc-endpoints-sg" })
}



# Create Interface Endpoints
# Allows private connectivity to AWS services without traversing public internet
resource "aws_vpc_endpoint" "interface_endpoints" {
  count = var.enable_vpc_endpoints ? length(var.vpc_interface_endpoints) : 0

  vpc_id            = aws_vpc.this.id
  service_name      = var.vpc_interface_endpoints[count.index]
  vpc_endpoint_type = "Interface"
  subnet_ids        = aws_subnet.private[*].id

  security_group_ids = [
    aws_security_group.vpc_endpoints_sg[0].id
  ]

  private_dns_enabled = true

  tags = merge(var.tags, {
    Name = "${var.name}-endpoint-${count.index}"
  })
}
