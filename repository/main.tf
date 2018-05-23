resource "aws_ecr_repository" "ecr-repo" {
  name = "${var.repository_name}"
}

resource "aws_iam_policy" "ecr-repo-push" {
  name        = "ecr-${var.repository_name}-push"
  path        = "/"
  description = "Push access to the ${var.repository_description} repository"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:DescribeImages",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:CompleteLayerUpload",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Effect": "Allow",
      "Resource": "${aws_ecr_repository.ecr-repo.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ecr-repo-pull" {
  name        = "ecr-${var.repository_name}-pull"
  path        = "/"
  description = "Pull access to the ${var.repository_description} repository"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:DescribeImages",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy"
      ],
      "Effect": "Allow",
      "Resource": "${aws_ecr_repository.ecr-repo.arn}"
    }
  ]
}
EOF
}

resource "aws_ecr_lifecycle_policy" "ecr-repo-policy" {
  repository = "${aws_ecr_repository.ecr-repo.name}"

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
