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

variable "efs_mount_point" {
  default = "/prometheus"
}
variable "efs_id" {
  default = ""
}
variable "efs_dns_name" {
  default = ""
}

variable "node_exporter_version" {
  default = "0.16.0"
}
