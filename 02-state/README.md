# Terraform State

Terraform state files (`terraform.tfstate`) act as a database that maps your real-world cloud resources to your configuration files. They are the last known checkpoints of your environment. 

This state file is Terraform's "source of truth". It must be protected, since it contains sensitive information, and if you lose the state file, Terraform will lose track of your environment and won't know which resources it is currently managing. 

## Deleting Resources

This will delete everything that is created previously. Any of our values in the terraform file do not matter, the command will delete what was previously created, not what is to be created.

```bash
terraform destroy
```

## Data Sources

In Terraform, there are two primary types of blocks for interacting with the cloud:

- **`resource` blocks:** For creating and managing *new* items in your cloud environment.
- **`data` blocks:** For searching your cloud environment to read information about *existing* items.

For example, instead of hardcoding an AMI ID (which changes frequently), we can use a `data` block to dynamically search AWS for the most recent Ubuntu AMI.

`main.tf`

```
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/*/ubuntu-*-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners  = ["099720109477"]  # Canonical
}

resource "aws_instance" "vm" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name = aws_key_pair.key.key_name
  vpc_security_group_ids = [ aws_security_group.sg.id ]
  subnet_id = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name = "userN"
  }
}
```

## Making Changes

When you need to modify your infrastructure, you edit the configuration files and run `terraform apply`. Terraform compares your desired configuration against the current state file, and determines what needs to change.

Some changes (like changing a tag or a security group rule) can be done on the fly without deleting the resource. This is called an **in-place update**.

Make the following simple change to your instance's name tag:

`main.tf`

```
resource "aws_instance" "vm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = [ aws_security_group.sg.id ]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name = "userN-newName"
  }
}
```

`~ update in-place`

Go to the AWS Web Console, find your VM, and manually change the name tag back to its original name (`userN`). Then, return to your terminal and run `terraform apply` again.

```bash
terraform apply
```

This demonstrates **Configuration Drift**. Terraform checks the real AWS environment, notices that someone manually changed the name (which causes the real world to "drift" from your configuration file), and will automatically update the resource to make it match your file again!

### Destructive Changes

Some changes cannot be applied on the fly. For example, if we change the AMI to upgrade the operating system from Ubuntu 22.04 to 24.04, Terraform must completely destroy the old VM and build a brand new one.

`main.tf`

```
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
```

Notice the `-/+ destroy and then create replacement` output. This means the underlying attribute (the OS disk) cannot be changed on a running machine. 

## Output

`main.tf`

```
output "public_ip"{
  value = aws_instance.vm.public_ip
  description = "The public IP address"
}
```

```bash
terraform apply
```

## Workspace

It's possible you'll want to apply the same terraform file more then once (dev, prod). If you try to do that normally you will encounter issues with the state file, changing the values isn't enough. When doing, the better method is to `workspaces`. 

Lets create a second workspace for testing and applying the same terraform file again. 

```bash
terraform workspace list

terraform workspace new dev
```

To check your current workspace, run the following. 

```bash
terraform workspace list
# or
terraform workspace show
```

Make sure your current workspace is `dev`, if not, select it with the command below.

```bash
terraform workspace select dev
```

Now that we're in the `dev` workspace, apply the same terraform again. 

```bash
terraform apply
```

On AWS you'll see duplicates of everything

```bash
terraform destroy
terraform select default
```

## Save to git

Time to save our progress!

```bash
git add .
git commit -m "Terraform state"
git push
```
