output "zone_id" {
  description = "The Zone ID of the Hosted Zone"
  value       = data.aws_route53_zone.this.zone_id
}
