output "redis_endpoint" {
  value = aws_instance.redis.private_ip
}
