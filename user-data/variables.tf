variable "environment" {}
variable "project" {}
variable "cluster_name" {}

variable "teleport_version" {
  default = "2.5.8"
}

variable "teleport_server" {
  default = ""
}

variable "teleport_auth_token" {
  default = ""
}
