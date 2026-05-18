# Terraform to Ansible Handoff

In this exercise, we will bridge the gap between Terraform and Ansible. 

You will use Terraform to spin up multiple EC2 instances, and then get Terraform to automatically generate an Ansible Inventory file containing the IP addresses of those newly created VMs. Once the infrastructure is up, you will run an Ansible playbook to configure all of them simultaneously.

## Provisioning with Terraform

First, we need to define our infrastructure. Make sure you create a new directory for this exercise. 

Create a `main.tf` file. We will use the `count` attribute to deploy 3 VMs. We will also introduce the `local_file` resource, which tells Terraform to create a file on your local workstation.

`main.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.44.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5.0"
    }
  }
}

provider "aws" {
  region = "ca-central-1"
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
  owners = ["099720109477"]
}

# Replace these variables with the actual IDs from your previous AWS lab!
variable "my_security_group_id" {
  default = "sg-XXXXXXXX" 
}
variable "my_subnet_id" {
  default = "subnet-XXXXXXXX" 
}
variable "my_key_name" {
  default = "userN"
}

resource "aws_instance" "vm" {
  count                       = 3
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  key_name                    = var.my_key_name
  vpc_security_group_ids      = [var.my_security_group_id]
  subnet_id                   = var.my_subnet_id
  associate_public_ip_address = true

  tags = {
    Name = "Ansible-Target-${count.index + 1}"
  }
}

# This powerful block automatically writes our Ansible inventory file!
resource "local_file" "ansible_inventory" {
  content = <<-EOT
    [webservers]
    %{ for ip in aws_instance.vm[*].public_ip ~}
    ${ip} ansible_user=ubuntu ansible_ssh_common_args='-o StrictHostKeyChecking=no'
    %{ endfor ~}
  EOT
  filename = "${path.module}/inventory.ini"
}
```

Make sure to update the `default` values in the variable blocks to match your actual Subnet ID, Security Group ID, and Key Pair Name from your AWS account. 

Initialize and apply your configuration:

```bash
terraform init
terraform apply
```

After Terraform finishes, check your folder. You should see a brand new `inventory.ini` file that Terraform automatically generated for you. 

## Configuration with Ansible

Now that we have our servers and an automatically generated inventory, we'll configure them with Ansible. 

Create a simple Ansible playbook called `playbook.yml`. This playbook will install Nginx on all the servers in the `[webservers]` group.

`playbook.yml`

```yaml
---
- name: Install and Start Nginx
  hosts: webservers
  become: yes
  tasks:
    - name: Ensure APT cache is updated
      apt:
        update_cache: yes

    - name: Install Nginx
      apt:
        name: nginx
        state: present

    - name: Ensure Nginx is running
      service:
        name: nginx
        state: started
        enabled: yes
```

## Execution and Verification

Because Terraform already generated the `inventory.ini` file for us with the correct IPs and SSH users, running Ansible is effortless.

Wait about 60 seconds to ensure the VMs have finished booting and SSH is available, then run your playbook:

```bash
ansible-playbook -i inventory.ini playbook.yml
```

Once the playbook completes, you should see green and yellow `ok` and `changed` statuses. 

Pick any of the IP addresses from your `inventory.ini` file and run a `curl` command against it (or open it in your browser):

```bash
curl http://<YOUR_VM_IP>
```

You should see the default "Welcome to nginx!" HTML page.

## Cleanup

Let's tear everything down.

```bash
terraform destroy
```
