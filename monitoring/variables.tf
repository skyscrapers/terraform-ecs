variable "environment" {
}
variable "cluster_name" {
}
variable "ecs_service_role" {

}
variable "desired_count" {
  default = "1"
}

variable "prometheus_port" {
  default = "9090"
}

variable "protocol" {
  default = "HTTP"
}
variable "https_listener" {
}

variable "vpc_id" {
}
variable "ecs_sg" {
}
variable "vpc_cidr" {
}

variable "priority" {
  default = "1"
}

variable "r53_zone" {
}

variable "alb_dns_name" {
}
