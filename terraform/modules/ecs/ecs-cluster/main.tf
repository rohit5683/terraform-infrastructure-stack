# ==============================================================================
# ECS Cluster Module
# ==============================================================================
# Creates the logical grouping for ECS Tasks and Services.
# Configures Capacity Providers (Fargate/Fargate Spot).

resource "aws_ecs_cluster" "this" {
  name = "${var.env}-rvdevops-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled" # Enable for detailed metrics ($$)
  }

  tags = var.tags
}

# Capacity Providers
# Defines the compute strategy. FARGATE = Serverless containers.
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 0
  }
}
