variable "repository_name" {
  description = "Name of the ECR repository"
}

variable "repository_description" {
  description = "Human readable description of the ECR repository"
}

variable "expire_after" {
  description = "Number of days after which untagged images in a repository will expire"
  default     = 30
}
