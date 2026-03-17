###############################################
# PUBLIC ALB OUTPUTS
###############################################

output "public_alb_dns" {
  value = aws_lb.public.dns_name
}

output "public_alb_arn" {
  value = aws_lb.public.arn
}

output "public_alb_zone_id" {
  value = aws_lb.public.zone_id
}


output "public_https_listener_arn" {
  value = aws_lb_listener.public_https.arn
}


###############################################
# INTERNAL ALB OUTPUTS (ONLY IF CREATED)
###############################################

output "internal_alb_dns" {
  value = var.create_internal_alb ? aws_lb.internal[0].dns_name : null
}

output "internal_alb_arn" {
  value = var.create_internal_alb ? aws_lb.internal[0].arn : null
}

output "internal_listener_arn" {
  value = var.create_internal_alb ? aws_lb_listener.internal_listener[0].arn : null
}


###############################################
# TARGET GROUP OUTPUTS
###############################################

output "frontend_tg_arn" {
  value = aws_lb_target_group.frontend_tg.arn
}

output "backend_tg_arn" {
  value = aws_lb_target_group.backend_tg.arn
}
