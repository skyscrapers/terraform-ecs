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

## EFS
Creates an Elastic Filesystem, mount points and cloud-config to mount at boot

### Available variables:
  * [`subnets`]: String(required): The subnets to create the mount point in
  * [`subnet_amount`]: String(required): The amount of subnets
  * [`project`]: String(optional): The project to tag EFS (default: "")
  * [`mount_point`]: String(optional): The mount point of EFS on the system (default: /media/efs)
  * [`name`]: String(optional): The name to tag EFS (default: efs)
  * [`security_groups`]: List(optional): The security groups to associate with the mount points (default: [] adds default security group)

### Output
  * [`cloud_config`]: The cloud config to mount efs at boot
  * [`dns_name`]: The DNS name of the elastic file system
  * [`efs_id`]: ID of the EFS
  * [`kms_key_id`]: KMS key used to encrypt EFS
  * [`mount_target_ids`]: List of mount target ids
  * [`mount_target_interface_ids`]: List of mount target interface ids

### Example
```
module "efs" {
  source          = "efs"
  project         = "myproject"
  subnets         = "${module.vpc.private_db}"
  subnet_amount   = 3
  security_groups = ["sg-ac66e1d6"]
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
 * [`datapoints_to_alarm_up`]: String(optional): ) The number of datapoints that must be breaching to trigger the alarm to scale up (default: 4)
 * [`datapoints_to_alarm_down`]: String(optional): The number of datapoints that must be breaching to trigger the alarm to scale down (default: 4)

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
