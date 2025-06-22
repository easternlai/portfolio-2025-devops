resource "aws_key_pair" "portfolio" {
  key_name   = "portfolio-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_security_group" "portfolio" {
  name        = "portfolio"
  description = "Allow Postgres and SSH"
  vpc_id      = aws_vpc.portfolio.id

  ingress {
    description = "PostgreSQL"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # Replace with your IP
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["73.71.103.99/32"] # Replace with your IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

resource "aws_instance" "portfolio" {
  ami                    = data.aws_ami.ubuntu.id # 
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.portfolio.key_name
  vpc_security_group_ids = [aws_security_group.portfolio.id]
  subnet_id              = values(aws_subnet.private)[0].id
  #   associate_public_ip_address = true


  user_data = templatefile("${path.module}/psql-ec2-provisioner.tpl", {
    db_user     = data.aws_ssm_parameter.username.value
    db_password = data.aws_ssm_parameter.password.value
    db_name     = "portfolio"
    }
  )

  tags = {
    Name = "db-${local.name}"
  }
}


resource "aws_instance" "jumpbox" {
  count                       = var.jumpbox ? 1 : 0
  ami                         = data.aws_ami.ubuntu.id # 
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.portfolio.key_name
  vpc_security_group_ids      = [aws_security_group.portfolio.id]
  subnet_id                   = values(aws_subnet.public)[0].id
  associate_public_ip_address = true


  tags = {
    Name        = "JB-${local.name}"
    description = "Jumpbox to reach internal Postgres DB"

  }
}
