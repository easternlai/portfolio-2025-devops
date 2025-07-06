resource "aws_security_group" "alb" {
  name   = "${local.name}-alb"
  vpc_id = aws_vpc.portfolio.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }

}

/* This subnet only gets created when there is only one AZ being deployed so 
   that we can satisfy the ALB requirement of having two subnets there by 
   reducing cost on resources that would exist on each AZ (Nat Gateway, etc). */

resource "aws_subnet" "placeholder" {

  count = length(var.public_subnets) < 2 ? 1 : 0

  vpc_id = aws_vpc.portfolio.id

  availability_zone = "${var.region}d"
  cidr_block        = var.public_subnets[(length(var.public_subnets) - 1)]

  tags = {
    Name = "${local.name}-alb-placeholder"
  }

}

resource "aws_alb" "portfolio" {
  name               = local.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  /* This logic will either concat public subnets to an empty array if more than two subnets/AZ's are used,
     or one public subnet to the placeholder subnet if only one subnet/AZ is used. */

  subnets = concat([for subnet in aws_subnet.public : subnet.id], aws_subnet.placeholder[*].id)

  enable_deletion_protection = false

  tags = {
    Name = local.name
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "${local.name}-frontend"
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.portfolio.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    name = local.name
  }

}


resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.portfolio.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_alb.portfolio.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.issued.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

resource "aws_route53_record" "alb_alias" {

  name    = "www.${trim(data.aws_route53_zone.easternlai-me.name, ".")}"
  zone_id = data.aws_route53_zone.easternlai-me.zone_id
  type    = "A"

  alias {
    name                   = aws_alb.portfolio.dns_name
    zone_id                = aws_alb.portfolio.zone_id
    evaluate_target_health = true
  }

}
