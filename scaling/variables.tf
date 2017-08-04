variable "cluster_name" {
  description = "Name of the cluster"
}

variable "service_name" {
  description = "Name of the service"
}

variable "evaluation_periods" {
  description = "Name of the service"
  default     = "4"
}

variable "period_down" {
  default = "120"
}

variable "period_up" {
  default = "60"  
}

variable "statistic" {
  default = "Average"  
}

variable "threshold_down" {
  default = "20"
}

variable "threshold_up" {
  default = "80"  
}

variable "min_capacity" {
  default = "1"
}

variable "max_capacity" {
  default = "4"  
}

variable "scaling_adjustment_down" {
  default = "-1"  
}

variable "scaling_adjustment_up" {
  default = "1"  
}

variable "lowerbound" {
  default = "0"  
}

variable "upperbound" {
  default = "0"  
}

variable "ecs_iam_role" {
    
}
