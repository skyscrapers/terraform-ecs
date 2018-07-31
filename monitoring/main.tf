data "aws_route53_zone" "root" {
  name = "${var.r53_zone}"
}

data "aws_region" "current" {}

data "template_file" "monitoring" {
  template = "${file("${path.module}/task-definitions/monitoring.json")}"

  vars {
    aws_region                      = "${data.aws_region.current.name}"
    version_prometheus              = "${var.version_prometheus}"
    cpu_prometheus                  = "${var.cpu_prometheus}"
    memory_prometheus               = "${var.memory_prometheus}"
    memory_reservation_prometheus   = "${var.memory_reservation_prometheus}"
    cpu_alertmanager                = "${var.cpu_alertmanager}"
    memory_alertmanager             = "${var.memory_alertmanager}"
    memory_reservation_alertmanager = "${var.memory_reservation_alertmanager}"
    version_alertmanager            = "${var.version_alertmanager}"
    environment                     = "${var.environment}"
  }
}

resource "aws_ecs_task_definition" "monitoring" {
  family                = "monitoring-${var.environment}"
  network_mode          = "bridge"
  container_definitions = "${data.template_file.monitoring.rendered}"
  task_role_arn         = "${aws_iam_role.prometheus.arn}"

  volume {
    name      = "prometheus"
    host_path = "/prometheus"
  }

  placement_constraints {
    expression = "attribute:type == prometheus"
    type       = "memberOf"
  }
}

resource "aws_ecs_service" "prometheus" {
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
    target_group_arn = "${aws_alb_target_group.prometheus.arn}"
    container_name   = "prometheus"
    container_port   = "${var.prometheus_port}"
  }
}

module "alb_listener_prometheus" {
  source                      = "github.com/skyscrapers/terraform-loadbalancers//alb_listener?ref=6.0.0"
  environment                 = "${var.environment}"
  project                     = "prometheus"
  vpc_id                      = "${var.vpc_id}"
  name_prefix                 = "https"
  alb_arn                     = "${var.alb_arn}"
  alb_sg_id                   = "${var.alb_sg_id}"
  https_certificate_arn       = "${var.alb_ssl_cert}"
  ingress_port                = "${var.prometheus_port}"
  create_default_target_group = false
  default_target_group_arn    = "${aws_alb_target_group.prometheus.arn}"
  source_subnet_cidrs         = "${var.source_subnet_cidrs}"

  tags = {
    Role = "loadbalancer"
  }
}

resource "aws_alb_target_group" "prometheus" {
  name     = "prometheus-${var.environment}"
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

resource "aws_security_group_rule" "inbound" {
  security_group_id = "${var.ecs_sg}"
  type              = "ingress"
  from_port         = "${var.prometheus_port}"
  to_port           = "${var.prometheus_port}"
  protocol          = "tcp"
  cidr_blocks       = ["${var.vpc_cidr}"]
}

resource "aws_route53_record" "prometheus" {
  zone_id = "${data.aws_route53_zone.root.zone_id}"
  name    = "prometheus.${var.r53_zone_prefix}${var.r53_zone}"
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
