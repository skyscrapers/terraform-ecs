data "aws_route53_zone" "root" {
  name = "${var.r53_zone}"
}

data "aws_region" "current" {}

locals {
  concourse_monitor = <<EOF
- job_name: 'concourse'
  scrape_interval: 15s
  static_configs:
    - targets: ['${var.concourse_url}:9391']
EOF
}
data "template_file" "monitoring" {
  template = "${file("${path.module}/task-definitions/monitoring.json")}"

  vars {
    aws_region                             = "${data.aws_region.current.name}"
    prometheus_version                     = "${var.prometheus_version}"
    prometheus_cpu                         = "${var.prometheus_cpu}"
    prometheus_memory                      = "${var.prometheus_memory}"
    prometheus_memory_reservation          = "${var.prometheus_memory_reservation}"
    alertmanager_cpu                       = "${var.alertmanager_cpu}"
    alertmanager_memory                    = "${var.alertmanager_memory}"
    alertmanager_memory_reservation        = "${var.alertmanager_memory_reservation}"
    alertmanager_version                   = "${var.alertmanager_version}"
    environment                            = "${var.environment}"
    cloudwatch_exporter_version            = "${var.cloudwatch_exporter_version}"
    cloudwatch_exporter_cpu                = "${var.cloudwatch_exporter_cpu}"
    cloudwatch_exporter_memory             = "${var.cloudwatch_exporter_memory}"
    cloudwatch_exporter_memory_reservation = "${var.cloudwatch_exporter_memory_reservation}"
    monitoring_configs_bucket              = "${aws_s3_bucket.monitoring_configs_bucket.id}"
  }
}

data "template_file" "grafana" {
  template = "${file("${path.module}/task-definitions/grafana.json")}"

  vars {
    aws_region                 = "${data.aws_region.current.name}"
    grafana_cpu                = "${var.grafana_cpu}"
    grafana_memory             = "${var.grafana_memory}"
    grafana_memory_reservation = "${var.grafana_memory_reservation}"
    grafana_version            = "${var.grafana_version}"
    grafana_port               = "${var.grafana_port}"
    environment                = "${var.environment}"
  }
}

resource "aws_ecs_task_definition" "monitoring" {
  family                = "monitoring-${var.environment}"
  network_mode          = "bridge"
  container_definitions = "${data.template_file.monitoring.rendered}"
  task_role_arn         = "${aws_iam_role.monitoring.arn}"

  volume {
    name      = "monitoring"
    host_path = "${var.mount_point}"
  }
}

resource "aws_ecs_task_definition" "grafana" {
  family                = "grafana-${var.environment}"
  network_mode          = "bridge"
  container_definitions = "${data.template_file.grafana.rendered}"
  task_role_arn         = "${aws_iam_role.monitoring.arn}"

  volume {
    name      = "grafana"
    host_path = "${var.mount_point}/grafana"
  }
}

resource "aws_ecs_service" "monitoring" {
  name            = "monitoring"
  cluster         = "${var.cluster_name}"
  task_definition = "${aws_ecs_task_definition.monitoring.arn}"
  desired_count   = "${var.desired_count}"
  iam_role        = "${var.ecs_service_role}"

  ordered_placement_strategy {
    type  = "spread"
    field = "host"
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.monitoring.arn}"
    container_name   = "prometheus"
    container_port   = "${var.prometheus_port}"
  }
}

resource "aws_ecs_service" "grafana" {
  name            = "grafana"
  cluster         = "${var.cluster_name}"
  task_definition = "${aws_ecs_task_definition.grafana.arn}"
  desired_count   = "${var.desired_count}"
  iam_role        = "${var.ecs_service_role}"

  ordered_placement_strategy {
    type  = "spread"
    field = "host"
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.grafana.arn}"
    container_name   = "grafana"
    container_port   = "${var.grafana_port}"
  }
}

module "alb_listener_monitoring" {
  source                      = "github.com/skyscrapers/terraform-loadbalancers//alb_listener?ref=6.0.0"
  environment                 = "${var.environment}"
  project                     = "monitoring"
  vpc_id                      = "${var.vpc_id}"
  name_prefix                 = "https"
  alb_arn                     = "${var.alb_arn}"
  alb_sg_id                   = "${var.alb_sg_id}"
  https_certificate_arn       = "${var.alb_ssl_cert}"
  ingress_port                = "${var.prometheus_port}"
  create_default_target_group = false
  default_target_group_arn    = "${aws_lb_target_group.monitoring.arn}"
  source_subnet_cidrs         = "${var.source_subnet_cidrs}"

  tags = {
    Role = "loadbalancer"
  }
}

resource "aws_lb_target_group" "monitoring" {
  name     = "monitoring-${var.environment}"
  port     = "${var.prometheus_port}"
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    interval            = 30
    path                = "/graph"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "grafana" {
  name     = "grafana-${var.environment}"
  port     = "${var.grafana_port}"
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    interval            = 30
    path                = "/api/health"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "grafana" {
  listener_arn = "${module.alb_listener_monitoring.listener_id}"
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.grafana.arn}"
  }

  condition {
    field  = "host-header"
    values = ["grafana.${var.r53_zone_prefix}${var.r53_zone}"]
  }
}

data "aws_vpc" "current" {
  id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "inbound" {
  security_group_id = "${var.ecs_sg}"
  type              = "ingress"
  from_port         = "${var.prometheus_port}"
  to_port           = "${var.prometheus_port}"
  protocol          = "tcp"
  cidr_blocks       = ["${data.aws_vpc.current.cidr_block}"]
}

resource "aws_security_group_rule" "allow_ecs_node_monitor" {
  type              = "ingress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  security_group_id = "${var.ecs_sg}"
  self              = true
}

resource "aws_security_group_rule" "allow_ecs_node_monitor_out" {
  type              = "egress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  security_group_id = "${var.ecs_sg}"
  self              = true
}

data "aws_lb" "alb" {
  arn  = "${var.alb_arn}"
}

resource "aws_route53_record" "monitoring" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "monitoring.${var.r53_zone_prefix}${var.r53_zone}"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.alb.dns_name}"
    zone_id                = "${data.aws_lb.alb.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "grafana" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "grafana.${var.r53_zone_prefix}${var.r53_zone}"
  type    = "A"

  alias {
    name                   = "${data.aws_lb.alb.dns_name}"
    zone_id                = "${data.aws_lb.alb.zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_cloudwatch_log_group" "cwlogs" {
  name              = "monitoring-${var.environment}"
  retention_in_days = "14"

  tags {
    Environment = "${var.environment}"
  }
}

resource "aws_s3_bucket" "monitoring_configs_bucket" {
  bucket = "monitoring-${var.environment}-${var.project}-state"
  acl    = "private"

  tags {
    Name        = "monitoring-${var.environment}-${var.project}-configs"
    Environment = "${var.environment}"
    Project     = "${var.project}"
  }
}

data template_file "alert_rules" {
  template = "${file("${path.module}/templates/alert.rules")}"

  vars {
    custom_alert_rules = "${indent(2,var.custom_alert_rules)}"
  }
}

data template_file "alertmanager_config" {
  template = "${file("${path.module}/templates/alertmanager.yml")}"

  vars {
    opsgenie_api_key = "${var.opsgenie_api_key}"
    environment      = "${var.environment}"
    project          = "${var.project}"
    slack_channel    = "${var.slack_channel}"
    slack_url        = "${var.slack_url}"
  }
}

data template_file "cloudwatch_exporter_config" {
  template = "${file("${path.module}/templates/cloudwatch_exporter.yml")}"

  vars {
    cloudwatch_metrics = "${indent(2,var.cloudwatch_metrics)}"
  }
}

data template_file "prometheus_config" {
  template = "${file("${path.module}/templates/prometheus.yml")}"

  vars {
    concourse_monitor= "${var.concourse_url == "" ? "": indent(2,local.concourse_monitor)}"
    custom_jobs      = "${indent(2,var.custom_jobs)}"
    environment      = "${var.environment}"
  }
}

resource "aws_s3_bucket_object" "alert_rules" {
  bucket  = "${aws_s3_bucket.monitoring_configs_bucket.id}"
  key     = "alert.rules"
  content = "${data.template_file.alert_rules.rendered}"
}

resource "aws_s3_bucket_object" "alertmanager_config" {
  bucket  = "${aws_s3_bucket.monitoring_configs_bucket.id}"
  key     = "alertmanager.yml"
  content = "${data.template_file.alertmanager_config.rendered}"
}

resource "aws_s3_bucket_object" "cloudwatch_exporter_config" {
  bucket  = "${aws_s3_bucket.monitoring_configs_bucket.id}"
  key     = "cloudwatch_exporter.yml"
  content = "${data.template_file.cloudwatch_exporter_config.rendered}"
}

resource "aws_s3_bucket_object" "prometheus_config" {
  bucket  = "${aws_s3_bucket.monitoring_configs_bucket.id}"
  key     = "prometheus.yml"
  content = "${data.template_file.prometheus_config.rendered}"
}
