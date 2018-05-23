output "repository-url" {
  value = "${aws_ecr_repository.ecr-repo.repository_url}"
}

output "repository-pull-policy" {
  value = "${aws_iam_policy.ecr-repo-pull.id}"
}

output "repository-push-policy" {
  value = "${aws_iam_policy.ecr-repo-push.id}"
}
