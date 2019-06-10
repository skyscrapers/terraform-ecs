resource "aws_efs_file_system" "efs" {
  encrypted = true

  tags = {
    Name        = var.name
    Environment = terraform.workspace
    Project     = var.project
  }
}

resource "aws_efs_mount_target" "efs" {
  file_system_id  = aws_efs_file_system.efs.id
  count           = var.subnet_amount
  subnet_id       = element(var.subnets, count.index)
  security_groups = var.security_groups
}

data "template_file" "efs" {
  template = file("${path.module}/cloud-config.yaml.tpl")

  vars = {
    mount_point = var.mount_point
    dns_name    = aws_efs_file_system.efs.dns_name
  }
}

