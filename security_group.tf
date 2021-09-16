resource "aws_security_group" "DigitalCheckList-Private-SG" {
  name = "Private SG"
  depends_on = [aws_vpc.DigitalCheckList-VPC]
  vpc_id = aws_vpc.DigitalCheckList-VPC.id

  ingress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [var.vpc-private-subnet-range, var.vpc-public-subnet-range]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [var.vpc-all-ips]
  }

  tags = {
    name = "Private SG for DigitalCheckList"
    project = var.project
  }

}

resource "aws_security_group" "nat-router-sg" {
  name = "NAT Router SG"
  vpc_id = aws_vpc.DigitalCheckList-VPC.id
  dynamic "ingress" {
    for_each = ["22"]
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = [var.vpc-all-ips]
    }
  }

  ingress {
    from_port = -1
    protocol = "icmp"
    to_port = -1
    cidr_blocks = [var.vpc-all-ips]
  }

  ingress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [var.vpc-private-subnet-range]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [var.vpc-all-ips]
  }

  tags = {
    name = "NAT Router SG for DigitalCheckList"
    project = var.project
  }
}

resource "aws_security_group" "DigitalCheckList-Public-SG" {
  name = "Load Balancer SG"
  vpc_id = aws_vpc.DigitalCheckList-VPC.id
  dynamic "ingress" {
    for_each = ["80","5000","27017","22"]
    content {
      from_port = ingress.value
      to_port = ingress.value
      protocol = "tcp"
      cidr_blocks = [var.vpc-all-ips]
    }
  }

  ingress {
    from_port = -1
    protocol = "icmp"
    to_port = -1
    cidr_blocks = [var.vpc-all-ips]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [var.vpc-all-ips]
  }

  tags = {
    name = "Public SG for DigitalCheckList"
    project = var.project
  }
}