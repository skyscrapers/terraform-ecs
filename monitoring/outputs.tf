output "alb_listener" {
  value = module.alb_listener_monitoring.listener_id
}

output "efs_mount_point" {
  value = var.mount_point
}

output "efs_dns_name" {
  value = module.efs_monitoring.dns_name
}

