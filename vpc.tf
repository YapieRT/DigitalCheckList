resource "aws_vpc" "DigitalCheckList-VPC" {
  cidr_block = var.vpc_range
  instance_tenancy = "default"
  assign_generated_ipv6_cidr_block = false

  tags = {
    name = "VPC for DigitalCheckList"
    project = var.project
  }
}

resource "aws_internet_gateway" "DigitalCheckList-IGW" {
  vpc_id = aws_vpc.DigitalCheckList-VPC.id

  tags = {
    name = "IGW for DigitalCheckList-VPC"
    project = var.project
  }
}

/* --------------------------- Public Subnet --------------------------- */

resource "aws_subnet" "DigitalCheckList-Public-Subnet" {
  cidr_block = var.vpc-public-subnet-range
  vpc_id = aws_vpc.DigitalCheckList-VPC.id
  availability_zone_id = data.aws_availability_zones.available.zone_ids[0]
  map_public_ip_on_launch = true

  tags = {
    name = "Public Subnet for DigitalCheckList"
    project = var.project
  }
}

resource "aws_route_table" "DigitalCheckList-Public-RouteTable" {
  vpc_id = aws_vpc.DigitalCheckList-VPC.id
  route {
    cidr_block = var.vpc-all-ips
    gateway_id = aws_internet_gateway.DigitalCheckList-IGW.id
  }

  tags = {
    name = "Route Table for Public Subnet of DigitalCheckList"
    project = var.project
  }
}

resource "aws_route_table_association" "DigitalCheckList-Public-RouteTable-Subnet-Association" {
  route_table_id = aws_route_table.DigitalCheckList-Public-RouteTable.id
  subnet_id = aws_subnet.DigitalCheckList-Public-Subnet.id
}

/* --------------------------- Private Subnet --------------------------- */

resource "aws_subnet" "DigitalCheckList-Private-Subnet" {
  cidr_block = var.vpc-private-subnet-range
  vpc_id = aws_vpc.DigitalCheckList-VPC.id
  availability_zone_id = data.aws_availability_zones.available.zone_ids[0]
  map_public_ip_on_launch = false

  tags = {
    name = "Private Subnet for DigitalCheckList"
    project = var.project
  }
}

resource "aws_route_table" "DigitalCheckList-Private-RouteTable" {
  vpc_id = aws_vpc.DigitalCheckList-VPC.id

  route {
    cidr_block = var.vpc-all-ips
    instance_id = aws_instance.nat-router.id
  }

  tags = {
    name = "Route Table for Private Subnet of DigitalCheckList"
    project = var.project
  }
}

resource "aws_route_table_association" "DigitalCheckList-Private-RouteTable-Subnet-Association" {
  route_table_id = aws_route_table.DigitalCheckList-Private-RouteTable.id
  subnet_id = aws_subnet.DigitalCheckList-Private-Subnet.id
}