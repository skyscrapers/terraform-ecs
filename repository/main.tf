resource "aws_ecr_repository" "ecr-repo" {
  name = var.repository_name
}

resource "aws_ecr_lifecycle_policy" "ecr-repo-policy" {
  count      = var.expire_after == 0 ? 0 : 1
  repository = aws_ecr_repository.ecr-repo.name

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire untagged images older than ${var.expire_after} days",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": ${var.expire_after}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF

}

