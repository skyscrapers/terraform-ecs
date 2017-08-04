
resource "aws_cloudwatch_metric_alarm" "alarm-cpu-down" {
  alarm_name          = "ECSServiceScaleInAlarm"
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

  alarm_description = "This metric monitors CPU utilization down"
  alarm_actions     = ["${aws_appautoscaling_policy.scale_down.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "alarm-cpu-up" {
  alarm_name          = "ECSServiceScaleOutAlarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "${var.evaluation_periods}"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "${var.period_up}"
  statistic           = "${var.statistic}"
  threshold           = "${var.threshold_up}"

  dimensions {
    ClusterName = "${var.cluster_name}"
    ServiceName = "${var.service_name}"
  }

  alarm_description = "This metric monitors CPU utilization up"
  alarm_actions     = ["${aws_appautoscaling_policy.scale_up.arn}"]
}


resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = "${var.max_capacity}"
  min_capacity       = "${var.min_capacity}"
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  role_arn           = "${var.ecs_iam_role}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_down" {
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 60
  metric_aggregation_type = "Maximum"
  name                    = "scale-down"
  resource_id             = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension      = "ecs:service:DesiredCount"
  service_namespace       = "ecs"

  step_adjustment {
    metric_interval_upper_bound = "${var.lowerbound}"
    scaling_adjustment          = "${var.scaling_adjustment_down}"
  }

  depends_on = ["aws_appautoscaling_target.ecs_target"]
}

resource "aws_appautoscaling_policy" "scale_up" {
  adjustment_type         = "ChangeInCapacity"
  cooldown                = 60
  metric_aggregation_type = "Maximum"
  name                    = "scale-up"
  resource_id             = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension      = "ecs:service:DesiredCount"
  service_namespace       = "ecs"

  step_adjustment {
    metric_interval_upper_bound = "${var.upperbound}"
    scaling_adjustment          = "${var.scaling_adjustment_up}"
  }

  depends_on = ["aws_appautoscaling_target.ecs_target"]
}
