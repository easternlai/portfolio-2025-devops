locals {
  name = "${var.env}-portfolio-${var.region}"
}

data "aws_acm_certificate" "issued" {
  domain      = "*.easternlai.me"
  statuses    = ["ISSUED"]
  most_recent = true
}

data "aws_route53_zone" "easternlai-me" {
  name         = "easternlai.me."
  private_zone = false
}

data "aws_ssm_parameter" "username" {
  name = "USERNAME"
}

data "aws_ssm_parameter" "password" {
  name = "PASSWORD"
}

data "aws_ssm_parameter" "host" {
  name = "HOST"
}
