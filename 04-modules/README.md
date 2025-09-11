# Terraform Modules

Modules make it easier to deploy complex resources. Resources that traverse multiple APIs.


For example, the network we created in this example. We created a VPC, then a subnet and an Internet Gateway with a default route for that gateway
*main.tf*
```
# VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.N.0.0/16"
  tags = {
    Name = "userN"
  }
}

# Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.N.1.0/24"
  availability_zone = "ca-central-1a"
  tags = {
    Name = "userN"
  }
}
# Internet Gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
}
# Internet Route
resource "aws_route" "route" {
  route_table_id = aws_vpc.userN.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.ig.id
}
```

With a module, all of that can be created at once

*main.tf*
```
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "module-vpc-user${var.user}"
  cidr = "10.${var.user}.0.0/16"

  azs             = ["ca-central-1a", "ca-central-1b", "ca-central1c"]
  private_subnets = ["10.${var.user}.2.0/24", "10.${var.user}.3.0/24"]
  public_subnets  = ["10.${var.user}.1.0/24"]

  create_egress_only_igw = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}
```

### Save to git
Time to save our progress!
```bash
git add .
git commit -m "Module"
git push

```