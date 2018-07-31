variable "environment" {}

variable "cluster_name" {}

variable "ecs_service_role" {}

variable "desired_count" {
  default = "1"
}

variable "prometheus_port" {
  default = "9090"
}

variable "protocol" {
  default = "HTTP"
}

variable "https_listener" {}

variable "vpc_id" {}

variable "ecs_sg" {}

variable "vpc_cidr" {}

variable "priority" {
  default = "1"
}

variable "r53_zone" {}

variable "r53_zone_prefix" {
  default = ""
}

variable "alb_dns_name" {}

variable "cpu_prometheus" {
  default = "0"
}

variable "memory_prometheus" {
  default = "100"
}

variable "memory_reservation_prometheus" {
  default = "100"
}

variable "cpu_alertmanager" {
  default = "0"
}

variable "memory_alertmanager" {
  default = "100"
}

variable "memory_reservation_alertmanager" {
  default = "100"
}

variable "version_prometheus" {
  default = "latest"
}

variable "version_alertmanager" {
  default = "latest"
}

variable "alb_arn" {}

variable "alb_sg_id" {}

variable "alb_ssl_cert" {}
