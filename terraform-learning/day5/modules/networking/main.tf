variable "vpc_cidr" {
  type = string
}

variable "env" {
  type = string
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env}-vpc"
    Env = var.env
  }
}

resource "aws_subnet" "public" {
  count = 2
  vpc_id = aws_vpc.main.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.env}-public-subnet-${count.index}"
    Env = var.env
  }
}

data "aws_availability_zone" "available" {
  state = "available"
}

output "subnet_ids" {
  value = aws_subnet.public[*].id
}