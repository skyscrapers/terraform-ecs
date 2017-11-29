resource "aws_ecs_task_definition" "definition" {
  family                = "${var.service_name}_${terraform.workspace}"
  container_definitions = "${var.template_data}"
  network_mode          = "bridge"
  task_role_arn         = "${aws_iam_role.role.arn}"
}


module "elb" {
  source                    = "github.com/skyscrapers/terraform-loadbalancers//elb_only_ssl_no_s3logs"
  name                      = "${var.service_name}"
  environment               = "${terraform.workspace}"
  subnets                   = ["${var.cluster_subnets}"]
  project                   = "${var.project}"
  ssl_certificate_id        = "${var.ssl_certificate_id}"  
  health_target             = "${var.health_target}"
  internal                  = "${var.internal}"
  instance_ssl_port         = "${var.container_port}"
  backend_security_groups   = ["${var.cluster_sg}"]
}

resource "aws_ecs_service" "container" {
  name            = "${var.service_name}_${terraform.workspace}"
  cluster         = "${var.ecs_cluster}"
  task_definition = "${aws_ecs_task_definition.definition.arn}"
  desired_count   = 1

  load_balancer {
    elb_name       = "${module.elb.elb_name}"
    container_name   = "${var.service_name}_${terraform.workspace}"
    container_port = "${var.container_port}"
  }

  placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  placement_strategy {
    type  = "spread"
    field = "instanceId"
  }
}


