# Terraform AWS

Before we can start with Terraform on AWS we'll need to login with the AWS cli. Terraform will use the local cli credentials to run commands

1. Login to AWS console
  <https://console.aws.amazon.com/console/home#>

  | Account ID | 257034520079 |
  | ---------- | ------------ |
  | Username   | userN        |
  | Password   |              |

1. In the top right corner, click on your username and go to `Security credentials`

2. Under `Access Keys` click `Create access key`

    a. Command Line Interface (CLI)

    b. Accept the risks, next
    
    c. Take note of the `Access Key` and `Secret Access Key`

3. On your workstation, run the following

    ```bash
    aws configure
    ```

    ```text
    AWS Access Key ID [****************5TF7]:
    AWS Secret Access Key [****************lJti]:
    Default region name [ca-central-1]:
    Default output format [None]:
    ```

    Enter your Access Key Id and Secret Access Key, and specify `ca-central-1` as the default region. Press Enter to skip the output format.

4. You can run the following to test your credentials. You should see your ARN in the output. 

    ```bash
    aws sts get-caller-identity
    ```

## First Deployment

Create a new file called `main.tf`. 

This will be the primary configuration file of the deployment. These files are written using either the HashiCorp Configuration Language or Json. These files are used to define your infrastructure as code (IaC). 

### Prerequisites

In the `main.tf` file, start by declaring the versions we want to use.

```
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.44.0"
    }
  }

  required_version = ">= 1.12.0"
}
```

This will do a few things. It will tell terraform we want to use the `hashicorp/aws` plugin and version 6.44.0 (which is the most current at the time of creating this).

These scripts have also been tested on terraform cli version 1.12 and it will be set as a minimum version.

Next we will provide some minimum data to the aws plugin. This information can be found in the plugin's [documentation](https://registry.terraform.io/providers/hashicorp/aws/5.99.1/docs). 

`main.tf`

```
provider "aws" {
  region = "ca-central-1"
}
```

### Networking

For the first example, we'll deploy a public network, with a internet gateway and a VM that will be remotely accessible. 

`main.tf`

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
```

Change `userN` to your user number. 

Change the `.N.` in the `cidr_blocks` to your user number as well. 

## Deploying

Before we can deploy anything we need to initialize Terraform. 

```bash
terraform init
```

Terraform will look for any `.tf` files in the current folder and read the `required_providers`, then download any that are missing. In this case, you should see it fetch the latest aws plugin.

Once initialized, we can `plan` the deployment. Terraform will again read the `.tf` files and give a report on what it will be doing to get to the desired state.

```bash
terraform plan
```

You'll notice every line starts with a `+`. This is because nothing currently exists, so everything is being created. This is exactly what we want, so we are good to go ahead a apply this terraform file. 

```bash
terraform apply
```

Terraform will show you the same plan again, there is a way to save a plan and just tell it to use the already planed changes but for now we'll let it recreate it.

Once done, it'll prompt you to continue. Type `yes` exactly. `y` or anything else will not work.

Once completed, you can go back to the AWS console and find your new VPC and subnet.

### Internet Accessible

To be able to reach the VMs from your workstation we'll need to make them publicly accessible. First we'll create an internet gateway. You can think of this as a endpoint on the public router. Next, we'll create a default route for the subnet that sends any unknown destination to that new IG (Internet Gateway). Last is the Security Group. For this, you'll need to know your public IP. If you need to find it, you can run the below command from your computer (not the workstation), or search "what's my ip" and your search engine should tell you.

To get current IP:

```bash
curl ifconfig.me
```

`main.tf`

```
# Internet Gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
}
# Internet Route
resource "aws_route" "route" {
  route_table_id = aws_vpc.vpc.default_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.ig.id
}

# Security Group
resource "aws_security_group" "sg" {
  name        = "UserN SG"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "ssh in"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<current IP>/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

After adding the above we can apply the new changes. 

```bash
terraform apply
```

You should see Terraform prompt you to create 3 new resources (the Internet Gateway, the Route, and the Security Group). Type `yes` to confirm. 

Now that our network is fully configured and accessible from your IP address, the final step is to deploy a Virtual Machine (EC2 instance) inside of it.

### Virtual Machine

To securely connect to the VM once it's created, we need to provide AWS with our public SSH key. We will create an `aws_key_pair` resource, and then assign that key pair to our new `aws_instance`.

In `main.tf`, add the following blocks. Make sure to replace `userN` with your assigned user number, and paste your actual public SSH key (from `~/.ssh/id_ed25519.pub`) into the `public_key` field.

```hcl
resource "aws_key_pair" "key" {
  key_name   = "userN"
  public_key = "ssh-rsa AAAAB... email@example.com"
}

resource "aws_instance" "vm" {
  ami                         = "ami-0df0e72a56b129d1f"
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.key.key_name
  vpc_security_group_ids      = [ aws_security_group.sg.id ]
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true

  tags = {
    Name = "userN"
  }
}
```

#### Outputting the IP Address

Once the VM is created, we will need to know its public IP address so we can connect to it. Instead of logging into the AWS Console to find it, we can tell Terraform to output the IP address directly to our terminal.

Add this output block to the end of your `main.tf`:

```hcl
output "vm_public_ip" {
  description = "The public IP address of the VM"
  value       = aws_instance.vm.public_ip
}
```

Apply these final changes:

```bash
terraform apply
```

Terraform will create the key pair and the EC2 instance. After it finishes, it will print an `Outputs:` section showing the `vm_public_ip`.

#### SSH Access

Now that the VM is running, you can connect to it! Use the IP address provided in the Terraform output, and the default `ubuntu` username for this specific AMI. 

```bash
ssh ubuntu@<vm_public_ip>
```

Since your Security Group allows port 22 from your current IP address, and your SSH key is authorized on the machine, you should be logged right in. 

## Save to git

Time to save our progress!

```bash
git add .
git commit -m "Terraform introduction"
git push

```
