resource "aws_iam_role" "ecs-autoscale-role" {
  name = "ecs-scale-${terraform.env}-${var.cluster_name}-${var.service_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "application-autoscaling.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_autoscale" {
  role       = "${aws_iam_role.ecs-autoscale-role.id}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

resource "aws_iam_role_policy_attachment" "ecs_cloudwatch" {
  role       = "${aws_iam_role.ecs-autoscale-role.id}"
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}
