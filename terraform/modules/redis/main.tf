# ==============================================================================
# Redis Module (Self-Managed EC2)
# ==============================================================================
# Provisions Redis on a raw EC2 instance instead of Elasticache.
# - Cost effective for small workloads.
# - Includes IAM Role for SSM Access (Connect without SSH keys).
# - Configures Redis secure settings via User Data script.

resource "aws_instance" "redis" {
  ami                  = var.ami_id != null ? var.ami_id : data.aws_ami.amazon_linux_2023.id
  instance_type        = var.instance_type
  subnet_id            = var.subnet_id
  iam_instance_profile = aws_iam_instance_profile.this.name

  vpc_security_group_ids = var.security_group_ids

  # User Data: Bootstrapping script run on first launch
  user_data = <<-EOF
              #!/bin/bash
              set -e

              # Update system
              dnf update -y || yum update -y

              # Install SSM Agent (for Session Manager access)
              dnf install -y amazon-ssm-agent || yum install -y amazon-ssm-agent
              systemctl enable amazon-ssm-agent
              systemctl start amazon-ssm-agent

              # Install redis6
              dnf install redis6 -y || yum install redis6 -y

              REDIS_CONF="/etc/redis6/redis6.conf"
              PRIVATE_IP=$(hostname -I | awk '{print $1}')

              # Backup config
              cp $REDIS_CONF $${REDIS_CONF}.bak

              # Bind to localhost + private IP (Allow network access)
              sed -i "s/^bind .*/bind 127.0.0.1 $PRIVATE_IP/" $REDIS_CONF

              # Enable auth
              sed -i "s/^# requirepass .*/requirepass ${var.password}/" $REDIS_CONF

              # Memory config
              sed -i "s/^# maxmemory .*/maxmemory ${var.maxmemory}/" $REDIS_CONF
              sed -i "s/^# maxmemory-policy .*/maxmemory-policy allkeys-lru/" $REDIS_CONF

              # Persistence (RDB only)
              sed -i "s/^save .*/save 300 10/" $REDIS_CONF
              sed -i "s/^appendonly .*/appendonly no/" $REDIS_CONF

              # Disable dangerous commands
              echo "rename-command FLUSHALL \"\"" >> $REDIS_CONF
              echo "rename-command FLUSHDB \"\"" >> $REDIS_CONF
              echo "rename-command CONFIG \"\"" >> $REDIS_CONF
              echo "rename-command SHUTDOWN \"\"" >> $REDIS_CONF

              # Enable & start redis
              systemctl enable redis6
              systemctl restart redis6
              EOF

  user_data_replace_on_change = true

  tags = merge(var.tags, {
    Name = "${var.env}-redis"
  })
}

# Image Data Source
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# IAM Role for SSM (No SSH keys required)
resource "aws_iam_role" "ssm_role" {
  name = "${var.env}-redis-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.env}-redis-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}
