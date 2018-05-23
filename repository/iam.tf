data "aws_iam_policy_document" "ecr-repo-push" {
  statement {
    sid = "1"

    actions = [
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
      "ecr:UploadLayerPart",
    ]

    resources = [
      "${aws_ecr_repository.ecr-repo.arn}",
    ]
  }
}

resource "aws_iam_policy" "ecr-repo-push" {
  name        = "ecr-${var.repository_name}-push"
  path        = "/"
  description = "Push access to the ${var.repository_description} repository"

  policy = "${data.aws_iam_policy_document.ecr-repo-push.json}"
}

data "aws_iam_policy_document" "ecr-repo-pull" {
  statement {
    sid = "1"

    actions = [
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
    ]

    resources = [
      "${aws_ecr_repository.ecr-repo.arn}",
    ]
  }
}

resource "aws_iam_policy" "ecr-repo-pull" {
  name        = "ecr-${var.repository_name}-pull"
  path        = "/"
  description = "Pull access to the ${var.repository_description} repository"

  policy = "${data.aws_iam_policy_document.ecr-repo-pull.json}"
}
