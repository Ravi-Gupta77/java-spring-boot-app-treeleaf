variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "tags" {
  description = "tags for resources"
  type        = map(string)
  default = {
    "Name" = "grafana-test"
    "terraform" = true
  }
}

variable "env" {
  description = "Name of the environment"
  type        = string
  default     = "qa"
}