module "ecs_cluster" {
  source      = "../ecs-cluster"
  project     = "myproject"
  environment = "production"
}
