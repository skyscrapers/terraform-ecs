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
 * [`service_name`]: String(required): The name of the ECS service.
 * [`evaluation_periods`]: String(optional): Evaluation period for the cloudwatch alarms (default: 4)
 * [`threshold_down`]: String(optional): Threshold when scaling down needs to happen. (default: 25)
 * [`threshold_up`]: String(optional): Threshold when scaling up needs to happen. (default: 75)
 * [`scale_up_adjustment`]: String(optional): Amount of tasks per check (maximum) that will be added. (default: 1)
 * [`scale_down_adjustment`]: String(optional): Amount of tasks per check (maximum) that will be removed. (default: -1)
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

## ecs-service
Setup an ecs service without elb
### Available variables:
 * [`ecs_cluster`]: String(required): The name of the ECS cluster.
 * [`service_name`]: String(required): The name of the ECS service.
 * [`template_data`]: String(required): The rendered template file data definition 
### Example:
```
module "ecs_service" {
  source              = "https://github.com/skyscrapers/terraform-ecs//ecs-service"
  service_name        = "${var.service_name}"
  template_data       = "${data.template_file.task.rendered}"
  ecs_cluster         = "${data.terraform_remote_state.ecs.ecs_cluster}"
}
```

## ecs-service
Setup an ecs service with elb, only ssl no s3 logs type
### Available variables:
 * [`ecs_cluster`]: String(required): The name of the ECS cluster.
 * [`cluster_subnet`]: String(required): The subnet ID of the cluster VPC
 * [`cluster_sg`]: String(required): The security groups of the cluster
 * [`service_name`]: String(required): The name of the ECS service.
 * [`template_data`]: String(required): The rendered template file data definition
 * [`container_port`]: String(required): The port number to connect to from the ELB
 * [`ssl_certificate_id`]: String(required): The arn of the ssl certficate to use for the ELB
 * [`health_target`]: String(required): The target of the check. Valid pattern is ${PROTOCOL}:${PORT}${PATH}
 * [`domain`]: String(required): The domain name to host the service. URL will be ${var.service_name}.${var.domain} 

### Example:
```
module "ecs_service" {
  source              = "https://github.com/skyscrapers/terraform-ecs//ecs-service_with_elb"
  service_name        = "${var.service_name}"
  template_data       = "${data.template_file.task.rendered}"
  ecs_cluster         = "${data.terraform_remote_state.ecs.ecs_cluster}"
  
}
```
