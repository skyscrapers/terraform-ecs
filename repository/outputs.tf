output "repository_url" {
  value = aws_ecr_repository.ecr-repo.repository_url
}

output "repository_pull_policy" {
  value = aws_iam_policy.ecr-repo-pull.id
}

output "repository_push_policy" {
  value = aws_iam_policy.ecr-repo-push.id
}

