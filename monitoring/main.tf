data "aws_route53_zone" "root" {
  name = "${var.r53_zone}"
}

data "aws_region" "current" {}

data "template_file" "monitoring" {
  template = "${file("${path.module}/task-definitions/monitoring.json")}"

  vars {
    aws_region                             = "${data.aws_region.current.name}"
    version_prometheus                     = "${var.version_prometheus}"
    cpu_prometheus                         = "${var.cpu_prometheus}"
    memory_prometheus                      = "${var.memory_prometheus}"
    memory_reservation_prometheus          = "${var.memory_reservation_prometheus}"
    cpu_alertmanager                       = "${var.cpu_alertmanager}"
    memory_alertmanager                    = "${var.memory_alertmanager}"
    memory_reservation_alertmanager        = "${var.memory_reservation_alertmanager}"
    version_alertmanager                   = "${var.version_alertmanager}"
    environment                            = "${var.environment}"
    version_cloudwatch_exporter            = "${var.version_cloudwatch_exporter}"
    cpu_cloudwatch_exporter                = "${var.cpu_cloudwatch_exporter}"
    memory_cloudwatch_exporter             = "${var.memory_cloudwatch_exporter}"
    memory_reservation_cloudwatch_exporter = "${var.memory_reservation_cloudwatch_exporter}"
    monitoring_configs_bucket              = "${aws_s3_bucket.monitoring_configs_bucket.id}"
  }
}

data "template_file" "grafana" {
  template = "${file("${path.module}/task-definitions/grafana.json")}"

  vars {
    aws_region                 = "${data.aws_region.current.name}"
    cpu_grafana                = "${var.cpu_grafana}"
    memory_grafana             = "${var.memory_grafana}"
    memory_reservation_grafana = "${var.memory_reservation_grafana}"
    version_grafana            = "${var.version_grafana}"
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
  protocol = "${var.protocol}"
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
  protocol = "${var.protocol}"
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

resource "aws_security_group_rule" "inbound" {
  security_group_id = "${var.ecs_sg}"
  type              = "ingress"
  from_port         = "${var.prometheus_port}"
  to_port           = "${var.prometheus_port}"
  protocol          = "tcp"
  cidr_blocks       = ["${var.vpc_cidr}"]
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

resource "aws_route53_record" "monitoring" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "monitoring.${var.r53_zone_prefix}${var.r53_zone}"
  type    = "CNAME"
  records = ["${var.alb_dns_name}"]
  ttl     = "60"
}

resource "aws_route53_record" "grafana" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "grafana.${var.r53_zone_prefix}${var.r53_zone}"
  type    = "CNAME"
  records = ["${var.alb_dns_name}"]
  ttl     = "60"
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
    concourse_url    = "${var.concourse_url}"
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
