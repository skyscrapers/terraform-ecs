resource "aws_cloudwatch_metric_alarm" "ecs_service_scale_up_alarm" {
  alarm_name          = "${terraform.env}-${var.cluster_name}-${var.service_name}-ECSServiceScaleUpAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.evaluation_periods}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "${var.period_down}"
  statistic           = "${var.statistic}"
  threshold           = "${var.threshold_up}"
  dimensions {
    ClusterName = "${var.cluster_name}"
    ServiceName = "${var.service_name}"
  }
  alarm_description = "This metric monitor ecs CPU utilization up"
  alarm_actions     = ["${aws_appautoscaling_policy.scale_up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "ecs_service_scale_down_alarm" {
  alarm_name          = "${terraform.env}-${var.cluster_name}-${var.service_name}-ECSServiceScaleDownAlarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "${var.evaluation_periods}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "${var.period_down}"
  statistic           = "${var.statistic}"
  threshold           = "${var.threshold_down}"
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
  name                    = "${terraform.env}-${var.cluster_name}-${var.service_name}-scale-down"
  resource_id             = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension      = "ecs:service:DesiredCount"
  service_namespace       = "ecs"

  step_adjustment {
    metric_interval_upper_bound = "${var.upperbound}"
    scaling_adjustment          = "${var.scale_down_adjustment}"
  }

  depends_on = ["aws_appautoscaling_target.ecs_target"]
}

resource "aws_appautoscaling_policy" "scale_up" {
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 60
  metric_aggregation_type = "Maximum"
  name                    = "${terraform.env}-${var.cluster_name}-${var.service_name}-scale-up"
  resource_id             = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension      = "ecs:service:DesiredCount"
  service_namespace       = "ecs"

  step_adjustment {
    metric_interval_lower_bound = "${var.lowerbound}"
    scaling_adjustment          = "${var.scale_up_adjustment}"
  }

  depends_on = ["aws_appautoscaling_target.ecs_target"]
}
