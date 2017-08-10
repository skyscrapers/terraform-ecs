resource "aws_cloudwatch_metric_alarm" "ecs_cluster_scale_out_alarm" {
  alarm_name          = "${terraform.env}-${var.cluster_name}-ECSClusterScaleOutAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.evaluation_periods}"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "${var.period_down}"
  statistic           = "${var.statistic}"
  threshold           = "75"
  dimensions {
    ClusterName = "${var.cluster_name}"
  }
  alarm_description = "This metric monitor ecs CPU utilization up"
  alarm_actions     = ["${aws_autoscaling_policy.ecs_cluster_scale_out.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "ecs_cluster_scale_in_alarm" {
  alarm_name          = "${terraform.env}-${var.cluster_name}-ECSClusterScaleInAlarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "${var.evaluation_periods}"
  metric_name         = "CPUReservation"
  namespace           = "AWS/ECS"
  period              = "${var.period_down}"
  statistic           = "${var.statistic}"
  threshold           = "25"
  dimensions {
    ClusterName = "${var.cluster_name}"
  }
  alarm_description = "This metric monitor ecs CPU utilization down"
  alarm_actions     = ["${aws_autoscaling_policy.ecs_cluster_scale_in.arn}"]
}

resource "aws_autoscaling_policy" "ecs_cluster_scale_in" {
  name                   = "${terraform.env}-${var.cluster_name}-cluster-scale-in"
  policy_type            = "SimpleScaling"
  adjustment_type        = "PercentChangeInCapacity"
  scaling_adjustment     = -50
  cooldown               = 300
  autoscaling_group_name = "${var.ecs_autoscale_group_name}"
}

resource "aws_autoscaling_policy" "ecs_cluster_scale_out" {
  name                   = "${terraform.env}-${var.cluster_name}-cluster-scale-out"
  policy_type            = "SimpleScaling"
  adjustment_type        = "PercentChangeInCapacity"
  scaling_adjustment     = 100
  cooldown               = 300
  autoscaling_group_name = "${var.ecs_autoscale_group_name}"
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_scale_out_alarm" {
  alarm_name          = "${terraform.env}-${var.cluster_name}-ECSServiceScaleOutAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.evaluation_periods}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "${var.period_down}"
  statistic           = "${var.statistic}"
  threshold           = "75"
  dimensions {
    ClusterName = "${var.cluster_name}"
    ServiceName = "${var.service_name}"
  }
  alarm_description = "This metric monitor ecs CPU utilization up"
  alarm_actions     = ["${aws_appautoscaling_policy.scale_up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_scale_in_alarm" {
  alarm_name          = "${terraform.env}-${var.cluster_name}-ECSServiceScaleInAlarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "${var.evaluation_periods}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "${var.period_down}"
  statistic           = "${var.statistic}"
  threshold           = "25"
  dimensions {
    ClusterName = "${var.cluster_name}"
    ServiceName = "${var.service_name}"
  }
  alarm_description = "This metric monitor ecs CPU utilization down"
  alarm_actions     = ["${aws_appautoscaling_policy.scale_down.arn}"]
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = "${var.max_capacity}"
  min_capacity       = "${var.min_capacity}"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  role_arn           = "${aws_iam_role.ecs-autoscale-role.arn}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_down" {
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 60
  metric_aggregation_type = "Maximum"
  name                    = "${terraform.env}-${var.cluster_name}-service-scale-in"
  resource_id             = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension      = "ecs:service:DesiredCount"
  service_namespace       = "ecs"

  step_adjustment {
    metric_interval_upper_bound = "${var.lowerbound}"
    scaling_adjustment          = "-1"
  }

  depends_on = ["aws_appautoscaling_target.ecs_target"]
}

resource "aws_appautoscaling_policy" "scale_up" {
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 60
  metric_aggregation_type = "Maximum"
  name                    = "${terraform.env}-${var.cluster_name}-service-scale-out"
  resource_id             = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension      = "ecs:service:DesiredCount"
  service_namespace       = "ecs"

  step_adjustment {
    metric_interval_upper_bound = "${var.upperbound}"
    scaling_adjustment          = "1"
  }

  depends_on = ["aws_appautoscaling_target.ecs_target"]
}
