data "aws_route53_zone" "root" {
  name = "${var.r53_zone}"
}
#TODO: improve container configuration
resource "aws_ecs_task_definition" "prometheus" {
  family                = "prometheus-${var.environment}"
  network_mode          = "host"
  container_definitions = "${file("${path.module}/task-definitions/prometheus.json")}"
  task_role_arn         = "${aws_iam_role.prometheus.arn}"
  volume {
    name      = "prometheus"
    host_path = "/etc/prometheus"
  }
  placement_constraints {
  type       = "memberOf"
  expression = "attribute:type == prometheus"
}
}
resource "aws_ecs_service" "prometheus" {
  name            = "prometheus-${var.environment}"
  cluster         = "${var.cluster_name}"
  task_definition = "${aws_ecs_task_definition.prometheus.arn}"
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

resource "aws_alb_target_group" "prometheus" {
  name     = "prometheus-${var.environment}"
  port     = "${var.prometheus_port}"
  protocol = "${var.protocol}"
  vpc_id   = "${var.vpc_id}"

  health_check {
      interval = 30
      path = "/graph"
      timeout = 5
      healthy_threshold = 5
      unhealthy_threshold = 2
  }
}

resource "aws_alb_listener_rule" "prometheus" {
  listener_arn = "${var.https_listener}"
  priority     = "${var.priority}"

  action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.prometheus.arn}"
  }

  condition {
    field  = "host-header"
    values = ["prometheus.*"]
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
  name    = "prometheus.${var.r53_zone}"
  type    = "CNAME"
  records = ["${var.alb_dns_name}"] 
  ttl     = "60"
}
