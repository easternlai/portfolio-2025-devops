
data "aws_iam_policy_document" "lambda-assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda" {
  name               = "backend-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume.json
}

resource "aws_iam_role_policy" "lambda_networking" {
  name = "lambda-networking-and-logging"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowVPCNetworking"
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowLambdaLogging"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}


resource "aws_security_group" "lambda" {
  name        = "lambda-${local.name}"
  description = "for lambda function"
  vpc_id      = aws_vpc.portfolio.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lambda_function" "portfolio" {
  package_type  = "Image"
  function_name = local.name

  image_uri = var.ecr_repo_backend

  role = aws_iam_role.lambda.arn

  timeout       = 10
  memory_size   = 256
  architectures = ["arm64"]

  vpc_config {
    subnet_ids         = [values(aws_subnet.private)[0].id]
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      USERNAME = data.aws_ssm_parameter.username.value
      PASSWORD = data.aws_ssm_parameter.password.value
      HOST     = aws_instance.portfolio.private_ip
    }
  }

}

