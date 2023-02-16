provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}

resource "aws_vpc" "vpc_1" {
  cidr_block = var.vpc_cidr[0]

  tags = {
    Name = "${var.vpc_name_1}"
  }
}

resource "aws_vpc" "vpc_2" {
  cidr_block = var.vpc_cidr[1]

  tags = {
    Name = "${var.vpc_name_2}"
  }
}

resource "aws_subnet" "public_subnets_1" {
  count = 3
  vpc_id = aws_vpc.vpc_1.id
  cidr_block = "${var.subnet_prefix_1}${count.index+1}${var.subnet_postfix}"
  availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.public_subnet_name}-${count.index+1}"
  }
}

resource "aws_subnet" "public_subnets_2" {
  count = 3
  vpc_id = aws_vpc.vpc_2.id
  cidr_block = "${var.subnet_prefix_2}${count.index+1}${var.subnet_postfix}"
  availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.public_subnet_name}-${count.index+1}"
  }
}

resource "aws_subnet" "private_subnets_1" {
  count = 3
  vpc_id = aws_vpc.vpc_1.id
  cidr_block = "${var.subnet_prefix_1}${count.index+4}${var.subnet_postfix}"
  availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.private_subnet_name}-${count.index+1}"
  }
}

resource "aws_subnet" "private_subnets_2" {
  count = 3
  vpc_id = aws_vpc.vpc_2.id
  cidr_block = "${var.subnet_prefix_2}${count.index+4}${var.subnet_postfix}"
  availability_zone = "${var.aws_region}${var.availability_zones[count.index]}"

  tags = {
    Name = "${var.private_subnet_name}-${count.index+1}"
  }
}

resource "aws_internet_gateway" "gw1" {
  vpc_id = aws_vpc.vpc_1.id

  tags = {
    Name = "${var.gateway_name_1}"
  }
}

resource "aws_internet_gateway" "gw2" {
  vpc_id = aws_vpc.vpc_2.id

  tags = {
    Name = "${var.gateway_name_2}"
  }
}

resource "aws_route_table" "public_route_table_1" {
  vpc_id = aws_vpc.vpc_1.id

  route {
    cidr_block = var.rt_cidr
    gateway_id = aws_internet_gateway.gw1.id
  }

  tags = {
    Name = "${var.public_rt_name}"
  }
}

resource "aws_route_table" "public_route_table_2" {
  vpc_id = aws_vpc.vpc_2.id

  route {
    cidr_block = var.rt_cidr
    gateway_id = aws_internet_gateway.gw2.id
  }

  tags = {
    Name = "${var.public_rt_name}"
  }
}

resource "aws_route_table_association" "rt_associate_public_1" {
  count = 3
  subnet_id = aws_subnet.public_subnets_1[count.index].id
  route_table_id = aws_route_table.public_route_table_1.id
}

resource "aws_route_table_association" "rt_associate_public_2" {
  count = 3
  subnet_id = aws_subnet.public_subnets_2[count.index].id
  route_table_id = aws_route_table.public_route_table_2.id
}

resource "aws_route_table" "private_route_table_1" {

    vpc_id = aws_vpc.vpc_1.id

    tags = {
        Name = "${var.private_rt_name}"
    }
  
}

resource "aws_route_table" "private_route_table_2" {

    vpc_id = aws_vpc.vpc_2.id

    tags = {
        Name = "${var.private_rt_name}"
    }
  
}

resource "aws_route_table_association" "rt_associate_private_1" {
  count = 3
  subnet_id = aws_subnet.private_subnets_1[count.index].id
  route_table_id = aws_route_table.private_route_table_1.id
}

resource "aws_route_table_association" "rt_associate_private_2" {
  count = 3
  subnet_id = aws_subnet.private_subnets_2[count.index].id
  route_table_id = aws_route_table.private_route_table_2.id
}