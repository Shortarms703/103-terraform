# Terraform Variables

Until now everything has been defined as we used it. But Terraform offers the use of variables so things can either be set once and used often or change from environment to environment.

## First varialbe


One thing that would need to be set once and used often is the IP address to allow for our security group. As we open more and more services we'll always want it to be accessible from here only.

```

variable "lab_ip" {
  type = string
  default = "173.177.234.212/32"
}

.
.
.


#sec group
resource "aws_security_group" "sg" {
  name        = "UserN SH"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "ssh in"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.lab_ip]
  }
  ...
}

```

```bash
terraform apply
```

## Prompt for value

When a default value isn't given Terraform will ask for a value. We'll create a variable asking for which user number you are.

```
variable "user" {
  type = string
}
```


```bash
terraform apply
```

## Concatination

Modify your main.tf to use the new variable instead of being hardcoded

*main.tf*
```
resource "aws_vpc" "vpc" {
  cidr_block = "10.${var.user}.0.0/16"
  tags = {
    Name = "user${var.user}"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.${var.user}.1.0/24"
  availability_zone = "ca-central-1a"
  tags = {
    Name = "user${var.user}"
  }
}

# Security Group
resource "aws_security_group" "sg" {
  name        = "User${var.user} SG"
  vpc_id      = aws_vpc.vpc.id
  ...
}

.
.
.
resource "aws_key_pair" "key" {
  key_name   = "user${var.user}"
  ...
}
.
.
.
resource "aws_instance" "vm" {
  ...
  tags = {
    Name = "user${var.user} - newName"
  }
}
```

## Count

If you would want more then 1 VM created in AWS you would create an Auto-Scalling group, but that's not always available for onprem. In either case you can use Terraform to create multiple instances of the same VM. To do this you use the `count` attribute. It's not available on all resources but most support it.

Start by creating a variable asking for the ammount of VMs to create.

*main.tf*
```
variable "num_vms" {
  type = number
  description = "Number of VMs to create"
}
```

Then add the `count` to the aws_instance.

*main.tf*
```
resource "aws_instance" "vm" {
  count                       = "${var.num_vms}" 
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = [ aws_security_group.sg.id ]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name = "user${var.user} - newName"
  }
}
```

```bash
terraform apply
```

## Variable file

To keep everything organised the standard is to create a `variables.tf` file and declare all your variables there.

*variables.tf*
```
variable "num_vms" {
  type = number
  description = "Number of VMs to create"
}

variable "user" {
  type = string
}

variable "lab_ip" {
  type = string
  default = "173.177.234.212/32"
}
```

Next to stop the prompting we can create `.tfvars` file with values for our specific environment.


*workshop.tfvars*
```
num_vms = 2
user = N
```
Then when running the apply you can give it the file

```bash
tarraform apply --var-file workshop.tfvars
```
### Save to git
Time to save our progress!
```bash
git add .
git commit -m "variables"
git push

```
