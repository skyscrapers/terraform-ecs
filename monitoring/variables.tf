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

variable "prometheus_cpu" {
  default = "0"
}

variable "prometheus_memory" {
  default = "100"
}

variable "prometheus_memory_reservation" {
  default = "100"
}

variable "alertmanager_cpu" {
  default = "0"
}

variable "alertmanager_memory" {
  default = "100"
}

variable "alertmanager_memory_reservation" {
  default = "100"
}

variable "prometheus_version" {
  default = "v2.4.0"
}

variable "alertmanager_version" {
  default = "v0.15.1"
}

variable "cloudwatch_exporter_version" {
  default = "cloudwatch_exporter-0.5.0"
}

variable "alb_arn" {}

variable "alb_sg_id" {}

variable "alb_ssl_cert" {}

variable "source_subnet_cidrs" {
  type = "list"
}

variable "grafana_cpu" {
  default = "0"
}

variable "grafana_memory" {
  default = "100"
}

variable "grafana_memory_reservation" {
  default = "100"
}

variable "grafana_version" {
  default = "latest"
}

variable "grafana_port" {
  default = "3000"
}

variable "cloudwatch_exporter_cpu" {
  default = "100"
}

variable "cloudwatch_exporter_memory" {
  default = "200"
}

variable "cloudwatch_exporter_memory_reservation" {
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
