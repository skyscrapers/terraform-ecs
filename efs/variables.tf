variable "mount_point" {
  default = "/media/efs"
}

variable "name" {
  default = "efs"
}

variable "project" {
  default = ""
}

variable "security_groups" {
  default = []
  type    = "list"
}

variable "subnets" {
  type = "list"
}

# value of 'count' cannot be computed
variable "subnet_amount" {
  type = "string"
}
