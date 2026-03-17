variable "domain_name" {
  type = string
}
variable "certificate_arn" {
  type = string
} # ACM cert from us-east-1
variable "api_id" {
  type = string
}
variable "stage_name" {
  type        = string
  description = "API Gateway stage name to map to the custom domain"
}
variable "tags" {
  type    = map(string)
  default = {}
}
