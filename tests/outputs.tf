output "cluster_name" {
  value = "${module.ecs_cluster.cluster_name}"
}

output "ecs-instance-profile" {
  value = "${module.ecs_cluster.ecs-instance-profile}"
}

output "ecs-service-role" {
  value = "${module.ecs_cluster.ecs-service-role}"
}
