output "cluster_name" {
  value = "${aws_ecs_cluster.cluster.name}"
}

output "cluster_id" {
  value = "${aws_ecs_cluster.cluster.id}"
}

output "ecs-instance-profile" {
  value = "${aws_iam_instance_profile.ecs-instance-profile.name}"
}

output "ecs-service-role" {
  value = "${aws_iam_role.ecs-service-role.name}"
}
