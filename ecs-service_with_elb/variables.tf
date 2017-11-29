variable "aws_region" {
  default = "eu-west-1"
}

variable "service_name" {}

variable "template_data" {}

variable "ecs_cluster" {}

variable "cluster_subnets" {}

variable "cluster_sg" {}

variable "container_port" {}

variable "domain" {}

variable "ssl_certificate_id" {
  description = " The ARN of an SSL certificate you have uploaded to AWS IAM. Only valid when lb_protocol is either HTTPS or SSL"
}

variable "health_target" {
  description = "The target of the check. Valid pattern is ${PROTOCOL}:${PORT}${PATH}"
}

