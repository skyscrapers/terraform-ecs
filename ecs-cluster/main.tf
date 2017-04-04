resource "aws_ecs_cluster" "cluster" {
  name = "${var.project}-cluster-${var.environment}"
}
