locals {
  name = "${var.env}-portfolio-${var.region}"
}

variable "env" {
  type = string
}

variable "region" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "vpc_cidr" {
  type = string
}
