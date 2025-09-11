terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.99"
    }
  }

  required_version = ">= 1.12.0"
}

provider "aws" {
  region = "ca-central-1"
}

# VPC
resource "aws_vpc" "userN" {
cidr_block = "10.1.0.0/16"
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.userN.id
  cidr_block = "10.1.1.0/24"
  availability_zone = "ca-central-1a"
}

# Internet Gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.userN.id
}
# Internet Route
resource "aws_route" "route" {
  route_table_id = aws_vpc.userN.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.ig.id
}

# Security Group
resource "aws_security_group" "userNsg" {
  name        = "UserN SG"
  vpc_id      = aws_vpc.userN.id

  ingress {
    description = "ssh in"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["173.177.72.239/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_key_pair" "userN" {
  key_name   = "userN"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC1sOJVx+V0Cf4GG9SPkmHl5LXxSCMHSwzVNi+2RkxNV7t+/AEwJ117YFD+3HZwb691zKGa3vmQBMDjMi5RVNYbqs5TVEuBijj4ujDa6OjzD3PbuSueLCjPOLzWSzzxp0FqEuXumL0u+CIsoBWeHmeqGlgyLqJeur1FEV0h+wIJC/b38bbTEsWy+V9xWkPvUFitFRrGg2pHxbiRdsQNuCrr30P3di+0/kJZSLRb/+ghq7mIpLMdlf+AMj0BF41R3CA/a1EF61evp6zD+loCAdjWRfFxr9ysPHzyuEy0YPqh4p1fUDeI5pnmZUqs5v4H7swm5BHeBvVl1jy2b2QGrs1m+3O3J0yDge1UExVQ5u26BI5UzP1+4Fs/B946LFnl5Tggr02O33tGwUuLzlcIFe+HoXM52Ku3evG7z8TvHIFCRyS3qfFWIYK2rOYOXD+KNBailMHsEOHbwce3ovEcJUflKpWNrBO9Rkv1zQ5vF54nm99S2CbblWWHNMkarXNW1KM= jlevac@JUSTIN-K7FHQR4"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/*/ubuntu-*-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners  = ["099720109477"]  # Canonical
}

resource "aws_instance" "userN" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = aws_key_pair.userN.key_name
  vpc_security_group_ids = [ aws_security_group.userNsg.id ]
  subnet_id = aws_subnet.public.id
  associate_public_ip_address = true
  tags = {
    Name = "newName"
  }
}
