
resource "aws_vpc" "portfolio" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = local.name
  }
}

resource "aws_internet_gateway" "portfolio" {
  vpc_id = aws_vpc.portfolio.id

  tags = {
    Name = local.name
  }
}

resource "aws_subnet" "private" {

  for_each = toset(var.availability_zones)
  vpc_id   = aws_vpc.portfolio.id

  availability_zone = each.key
  cidr_block        = var.private_subnets[index(var.availability_zones, each.key)]

  tags = {
    Name = "${local.name}-private-${each.key}"
  }

}

resource "aws_subnet" "public" {

  for_each = toset(var.availability_zones)
  vpc_id   = aws_vpc.portfolio.id

  availability_zone = each.key
  cidr_block        = var.public_subnets[index(var.availability_zones, each.key)]

  tags = {
    Name = "${local.name}-public-${each.key}"
  }

}

resource "aws_eip" "nat-ip" {
  for_each = toset(var.availability_zones)
  domain   = "vpc"

  tags = {
    Name = local.name
  }

}

resource "aws_nat_gateway" "portfolio" {
  for_each      = toset(var.availability_zones)
  allocation_id = aws_eip.nat-ip[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = {
    Name = "${local.name}-${each.key}"
  }

  depends_on = [aws_internet_gateway.portfolio]
}

resource "aws_route_table" "private" {
  for_each = toset(var.availability_zones)
  vpc_id   = aws_vpc.portfolio.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.portfolio[each.key].id
  }

  tags = {
    Name = "${local.name}-private-${each.key}"
  }

}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.portfolio.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.portfolio.id
  }

  tags = {
    Name = "${local.name}-public"
  }

}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id

}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id

}
