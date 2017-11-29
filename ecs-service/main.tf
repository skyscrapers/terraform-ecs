resource "aws_ecs_task_definition" "definition" {
  family                = "${var.service_name}_${terraform.workspace}"
  container_definitions = "${var.template_data}"
  network_mode          = "bridge"
  task_role_arn         = "${aws_iam_role.role.arn}"
}

resource "aws_ecs_service" "container" {
  name            = "${var.service_name}_${terraform.workspace}"
  cluster         = "${var.ecs_cluster}"
  task_definition = "${aws_ecs_task_definition.definition.arn}"
  desired_count   = 1

  placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  placement_strategy {
    type  = "spread"
    field = "instanceId"
  }
}
