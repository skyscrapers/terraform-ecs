# terraform-ecs
Terraform ECS module

## ecs-cluster
Setup a basic ECS cluster with the needed IAM rights.

### Available variables:
 * [`project`]: String(required): Project name
 * [`environment`]: String(required):  For what environment is this cluster needed (eg staging, production, ...)
### Output
 * [`cluster_name`]: String: The name of the ECS cluster.
 * [`cluster_id`]: String: The ID (ARN) of the ECS cluster.
 * [`ecs-instance-profile`]: IAM instance profile that you need to give to your instances.
 * [`ecs-service-role`]: IAM service role for ECS to manage your loadbalancers
 * [`ecs-instance-role`]: IAM instance role name, useful to attach extra policies

### Example
```
module "ecs_cluster" {
  source      = "ecs_cluster"
  project     = "${var.project}"
  environment = "${terraform.env}"
}
```

## scaling
Setup a ECS cluster and service scaling.

### Available variables:
 * [`cluster_name`]: String(required): The name of the ECS cluster.
 * [`service_name`]: String(required): The name of the ECS cluster.
 * [`ecs_autoscale_group_name`]: String(required): The name of the autoscaling group on which scaling needs to be applied.
 * [`evaluation_periods`]: String(optional): Evaluation period for the cloudwatch alarms (default: 4)
 * [`period_down`]: String(optional): How long the threshold needs to be reached before a downscale happens. (default: 120)
 * [`period_up`]: String(optional): How long the threshold needs to be reached before a upscale happens. (default: 60)
 * [`statistic`]: String(optional): On what statistic the scaling needs to be based upon. (default: Average)
 * [`min_capacity`]: String(optional): Minimum amount of ECS task to run for a service. (default: 1)
 * [`max_capacity`]: String(optional): Maximum amount of ECS task to run for a service. (default: 4)

### Output

### Example
```
module "service-scaling" {
  source                   = "scaling"
  cluster_name             = "ecs-production"
  service_name             = "test-service"
  min_capacity             = "2"
  max_capacity             = "10"
  ecs_autoscale_group_name = "asg-production"
}
```
