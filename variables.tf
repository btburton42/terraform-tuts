variable "region" {
  description = "The AWS region."
  default     = "us-west-2"
}

variable "ami" {
  type    = "map"
  description = "A map of AMIs."
  default = {}
}
variable "instance_type" {
  description = "The instance type."
  default = "m1.small"
}

variable "instance_ips" {
  description = "The IPs to use for our instances"
  default = ["10.0.1.20", "10.0.1.21"]
}

variable "owner_tag" {
  default = ["team1", "team2"]
}

variable "environment" {
  default = "development"
}

variable "key_path" {
  default = "/Users/tyler.burton/.ssh/aws_keys/TestKeyPair.pem"
}
