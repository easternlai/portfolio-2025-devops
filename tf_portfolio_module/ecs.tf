resource "aws_ecs_cluster" "portfolio" {
  name = local.name

  #   setting {
  #     name  = "containerInsights"
  #     value = "enabled"
  #   }
}
resource "aws_security_group" "ecs-service" {
  name   = "${local.name}-ecs-service"
  vpc_id = aws_vpc.portfolio.id

  ingress {
    from_port   = 3000
    to_port     = 3000
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

resource "aws_ecs_service" "portfolio" {
  depends_on      = [aws_alb.portfolio, aws_subnet.private]
  name            = "${local.name}-frontend"
  cluster         = aws_ecs_cluster.portfolio.arn
  task_definition = aws_ecs_task_definition.portfolio.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [for s in aws_subnet.private : s.id]
    security_groups  = [aws_security_group.ecs-service.id]
    assign_public_ip = false

  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "${local.name}-frontend"
    container_port   = 3000
  }

}


resource "aws_ecs_task_definition" "portfolio" {
  family                   = "${local.name}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "${local.name}-frontend"
      image = "856660075226.dkr.ecr.us-west-2.amazonaws.com/portfolio-frontend-2025:latest"
      #   cpu       = 10
      #   memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
    }
  ])

  runtime_platform {
    cpu_architecture        = "ARM64"
    operating_system_family = "LINUX"
  }

}

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole-portfolio"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_container_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}
