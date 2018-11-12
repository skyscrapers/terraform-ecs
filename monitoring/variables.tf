variable "environment" {}
variable "project" {}

variable "cluster_name" {}

variable "ecs_service_role" {}

variable "desired_count" {
  default = "1"
}

variable "prometheus_port" {
  default = "9090"
}

variable "vpc_id" {}

variable "ecs_sg" {}

variable "r53_zone" {}

variable "r53_zone_prefix" {
  default = ""
}

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
  default = "v2.4.0"
}

variable "version_alertmanager" {
  default = "v0.15.1"
}

variable "version_cloudwatch_exporter" {
  default = "cloudwatch_exporter-0.5.0"
}

variable "alb_arn" {}

variable "alb_sg_id" {}

variable "alb_ssl_cert" {}

variable "source_subnet_cidrs" {
  type = "list"
}

variable "cpu_grafana" {
  default = "0"
}

variable "memory_grafana" {
  default = "100"
}

variable "memory_reservation_grafana" {
  default = "100"
}

variable "version_grafana" {
  default = "latest"
}

variable "grafana_port" {
  default = "3000"
}

variable "cpu_cloudwatch_exporter" {
  default = "100"
}

variable "memory_cloudwatch_exporter" {
  default = "200"
}

variable "memory_reservation_cloudwatch_exporter" {
  default = "100"
}

variable "opsgenie_api_key" {}

variable "slack_channel" {}
variable "slack_url" {}
variable "custom_jobs" {
  default = ""
}
variable "concourse_url" {
  default = ""
}

variable "cloudwatch_metrics" {
  default = ""
}
variable "custom_alert_rules" {
  default = ""
}

variable "efs_subnets" {
  type = "list"
}

variable "mount_point" {
  default = "/monitoring"
}
