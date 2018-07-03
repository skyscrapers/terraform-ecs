output "cluster_name" {
  value = "${aws_ecs_cluster.cluster.name}"
}

output "cluster_id" {
  value = "${aws_ecs_cluster.cluster.id}"
}

output "ecs-instance-profile" {
  value = "${aws_iam_instance_profile.ecs-instance-profile.name}"
}

output "ecs_instance_profile_arn" {
  value = "${aws_iam_instance_profile.ecs-instance-profile.arn}"
}

output "ecs-service-role" {
  value = "${aws_iam_role.ecs-service-role.name}"
}

output "ecs-instance-role" {
  value = "${aws_iam_role.ecs-instance-role.name}"
}
