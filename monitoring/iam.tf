data "aws_iam_policy_document" "monitoring" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  name               = "monitoring-task-role-${var.environment}"
  assume_role_policy = "${data.aws_iam_policy_document.monitoring.json}"
}

data "aws_iam_policy_document" "s3_monitoring_config" {
  statement {
    actions = ["s3:*"]
    effect  = "Allow"

    resources = [
      "${aws_s3_bucket.monitoring_configs_bucket.arn}",
      "${aws_s3_bucket.monitoring_configs_bucket.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "s3_monitoring_config_policy" {
  name   = "s3-monitoring-config-${var.environment}"
  role   = "${aws_iam_role.monitoring.id}"
  policy = "${data.aws_iam_policy_document.s3_monitoring_config.json}"
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = "${aws_iam_role.monitoring.id}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

