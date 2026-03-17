variable "env" {
  type = string
}
variable "private_subnets" {
  type = list(string)
}
variable "apigw_vpclink_sg_id" {
  type = string
} # pass module.sg.apigw_vpclink_sg_id
variable "tags" {
  type    = map(string)
  default = {}
}
