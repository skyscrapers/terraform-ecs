# terraform-ecs
Terraform ECS module

## ecs-cluster
Setup a basic ECS cluster with the needed IAM rights.

### Available variables:
 * [`project`]: String(required): Project name
 * [`environment`]: String(optional):  For what environment is this cluster needed (eg staging, production, ...)
### Output
 * [`cluster_name`]: String: The name of the ECS cluster.
 * [`ecs-instance-profile`]: IAM instance profile that you need to give to your instances.
 * [`ecs-service-role`]: IAM service role for you ECS to manage your loadbalancers

### Example
```
module "ecs_cluster" {
  source      = "ecs_cluster"
  project     = "myproject"
  environment = "production"
}
```
