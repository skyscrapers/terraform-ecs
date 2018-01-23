/**
 * Instance profile for instances launched by autoscaling
 */

resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name = "ecs-instance-profile-${var.environment}"
  role = "${aws_iam_role.ecs-instance-role.name}"
}

resource "aws_iam_role" "ecs-instance-role" {
  name = "ecs-instance-role-${var.environment}"

  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-policy-attach" {
  role       = "${aws_iam_role.ecs-instance-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

/**
 * Role for ecs to edit the loadbalancers
 */

resource "aws_iam_role" "ecs-service-role" {
  name = "ecs-service-role-${var.environment}"

  assume_role_policy = <<EOF
{
 "Version": "2008-10-17",
 "Statement": [
   {
     "Sid": "",
     "Effect": "Allow",
     "Principal": {
       "Service": "ecs.amazonaws.com"
     },
     "Action": "sts:AssumeRole"
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-service-role-policy-attach" {
  role       = "${aws_iam_role.ecs-service-role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
