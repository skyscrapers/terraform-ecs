variable "environment" {
}

variable "project" {
}

variable "cluster_name" {
}

variable "teleport_version" {
  default = "10.1.4"
}

variable "teleport_server" {
  default = ""
}

variable "teleport_auth_token" {
  default = ""
}

variable "efs_mount_point" {
  default = "/efs"
}

variable "efs_dns_name" {
  default = ""
}

variable "node_exporter_version" {
  default = "0.16.0"
}
