# ==============================================================================
# Application Load Balancer Module
# ==============================================================================
# Manages L7 Load Balancers for traffic distribution.
# - Public ALB: Frontend and Public API traffic
# - Internal ALB (Conditional): Private API traffic (e.g. behind API Gateway)
# - Listeners & Rules: Routing logic (Host-based routing)

# ------------------------------------------------------------------------------
# 1. PUBLIC ALB
# ------------------------------------------------------------------------------
resource "aws_lb" "public" {
  name                       = "${var.env}-public-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.alb_sg_id]
  enable_deletion_protection = false
  subnets                    = var.public_subnets
  tags                       = var.tags
}


# ------------------------------------------------------------------------------
# 2. INTERNAL ALB (Optional - Prod Strategy)
# ------------------------------------------------------------------------------
resource "aws_lb" "internal" {
  count              = var.create_internal_alb ? 1 : 0
  name               = "${var.env}-internal-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [var.internal_alb_sg_id]
  subnets            = var.internal_subnets
  tags               = var.tags
}


# ------------------------------------------------------------------------------
# 3. TARGET GROUPS
# ------------------------------------------------------------------------------

# Frontend Target Group
resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.env}-frontend-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip" # Required for Fargate
  vpc_id      = var.vpc_id

  health_check {
    path                = var.frontend_health_check_path
    protocol            = "HTTP"
    matcher             = var.health_check_matcher
    interval            = 20
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  tags = var.tags
}

# Backend Target Group
resource "aws_lb_target_group" "backend_tg" {
  name        = "${var.env}-backend-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = var.backend_health_check_path
    protocol            = "HTTP"
    matcher             = var.health_check_matcher
    interval            = 20
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  tags = var.tags
}


# ------------------------------------------------------------------------------
# 4. PUBLIC LISTENERS
# ------------------------------------------------------------------------------

# HTTP -> HTTPS Redirect
resource "aws_lb_listener" "public_http" {
  load_balancer_arn = aws_lb.public.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS Listener (Termination)
resource "aws_lb_listener" "public_https" {
  load_balancer_arn = aws_lb.public.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.acm_certificate_arn

  # Default Action: Send to Frontend
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}


# ------------------------------------------------------------------------------
# 5. PUBLIC ALB RULES (Routing)
# ------------------------------------------------------------------------------
# Directs traffic based on Host Header (e.g. app.example.com vs api.example.com)
# Typically used in Dev/Stage. Prod may use CloudFront/API Gateway instead.

resource "aws_lb_listener_rule" "frontend_rule" {
  count        = var.enable_public_routing_rules ? 1 : 0
  listener_arn = aws_lb_listener.public_https.arn
  priority     = 1

  condition {
    host_header {
      values = ["app.${var.domain_name}"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "backend_rule" {
  count        = var.enable_public_routing_rules && !var.create_internal_alb ? 1 : 0
  listener_arn = aws_lb_listener.public_https.arn
  priority     = 2

  condition {
    host_header {
      values = ["api.${var.domain_name}"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# ------------------------------------------------------------------------------
# 6. INTERNAL ALB LISTENER (Prod)
# ------------------------------------------------------------------------------
# Listens for traffic from API Gateway (via VPC Link)
resource "aws_lb_listener" "internal_listener" {
  count             = var.create_internal_alb ? 1 : 0
  load_balancer_arn = aws_lb.internal[0].arn
  port              = 3000
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}
