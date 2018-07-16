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
 * [`ecs_instance_profile_arn`]: IAM instance profile arn that you need to give to your instances.
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

## Repository
Creates an Elastic Container Registry with associated pull & push policies.
The created pull & push policies can be used as policy attachments on AWS roles.

### Available variables:
  * [`repository_name`]: String(required): The name of the ECR repository
  * [`expire_after`]: Integer(optional): The amount of days after which untagged images expire. Set to 0 if you do not want a lifecycle policy. (default: 30)

### Output
  * [`repository_url`]: The url to the ECR repository
  * [`repository_push_policy`]: The id of the push policy to this ECR repository.
  * [`repository_pull_policy`]: The id of the pull policy to this ECR repository.

### Example
```
module "jenkins-repo" {
  source                 = "github.com/skyscrapers/terraform-ecs//repository"
  repository_name        = "jenkins"
  repository_description = "Jenkins Master"
  expire_after           = 14
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

## user-data
Setup a ECS cluster and service user-data.

### Available variables:
 * [`project`]: String(optional): The project to tag EFS (default: "")
 * [`environment`]: String(required):  For what environment is this cluster needed (eg staging, production, ...)
 * [`cluster_name`]: String(required): The name of the ECS cluster.
 * [`teleport_version`]: String(required): The version of Teleport to be used (default: 2.5.8).
 * [`teleport_server`]: String(optional): the name of the teleport server to connect to(default: "")
 * [`teleport_auth_token`]: String(optional): Teleport server node token (default: "")

### Output

### Example
```
module "service-user-data" {
  source                   = "user-data"
  project             = "${var.project}"
  environment         = "${terraform.workspace}"
  teleport_auth_token = "${data.aws_kms_secret.secret.auth_token}"
  teleport_version    = "${var.teleport_version}"
  teleport_server     = "${var.teleport_server}"
  cluster_name        = "${module.ecs_cluster.cluster_name}"
}
```

## CI/CD

In the `ci` folder you can find some tasks definition for automating deployment with `concourse`

### ECS
This folder contians a script that can be used to automatically update the ecs AMI.
It also contains a concourse task definition that allows to use the script in a concourse pipeline.

In order to add this task in a pipeline you need to specify the following inputs:
 * [`terraform-ecs`] : This git repo
 * [`terraform-repo`] : The git repo with the terraform code that contains the ecs cluster
 * [`ami`] : The ami resource that we want to deploy

 You can customize your pipeline with the following params:
 * [`TF_PROJECT_FOLDER`] : The folder that contains the ecs cluster definition
 * [`TF_VERSION`] : The terraform version of the project
 * [`AWS_DEFAULT_REGION`] : The AWS region where the ecs cluster has been deployed
 * [`ROLE_TO_ASSUME`] : The role to assume in order to run terraform
 * [`TIMEOUT`] : The time the script will wait for the container to migrate to the new instances
 * [`TF_ENVIRONMENT`] : The terraform workspace to target
 * [`AWS_ACCOUNT_ID`] : The account_id where the infra has been deployed

An example of a concourse pipeline can be found in the [example pipeline](ci/ecs/sample.yml)
