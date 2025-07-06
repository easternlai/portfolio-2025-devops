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

variable "jumpbox" {
  type = bool
}

variable "ecr_repo_frontend" {
  type = string
}

variable "ecr_repo_backend" {
  type = string
}
