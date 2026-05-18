# Installing Terraform

<https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli>

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint
# Note: We hardcode 'jammy' here because HashiCorp's repository does not always have the terraform package available for newer releases like 'noble' (Ubuntu 24.04). The jammy package works perfectly.
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform
```

## Create Terraform repo in Git

Let save all our work in git to ensure no loss of work in the case the VM goes down.

1. Create a repository

      Got to Gitea and create a repository called TerraformCourse_{username}

2. Create local repository and connect to remote

      ```bash
      mkdir terraform
      cd terraform
      touch README.md
      git init
      git checkout -b main
      git add README.md
      git commit -m "first commit"
      git remote add origin <remote_repository_URL>
      git push -u origin main
      ```

## Install AWS CLI

To install the AWS CLI, run the following:

```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

These commands are from the AWS documentation, see [Installing or updating to the latest version of the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

To test your installation, run the following:

```bash
aws --version
```
