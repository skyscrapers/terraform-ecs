resource "aws_security_group" "efs" {
  name_prefix = "efs"
  vpc_id      = var.vpc_id
}

resource "aws_security_group_rule" "allow_all" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  source_security_group_id = var.ecs_sg

  security_group_id = aws_security_group.efs.id
}

resource "aws_security_group_rule" "allow_efs_out" {
  type                     = "egress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = var.ecs_sg
  source_security_group_id = aws_security_group.efs.id
}

module "efs_monitoring" {
  source          = "../efs"
  project         = var.project
  name            = "monitoring-${var.environment}"
  subnet_amount   = length(var.efs_subnets)
  subnets         = [var.efs_subnets]
  security_groups = [aws_security_group.efs.id]
}

