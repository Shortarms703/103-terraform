# Installing Terraform
https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli

```bash
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
gpg --no-default-keyring \
--keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
--fingerprint
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform
```

## create Terraform repo in Git
Let save all our work in git to ensure no loss of work in the case the VM goes down.
1. Create a repository
Got to Gittea and create a repository called TerraformCourse_{username}

2. Create local repository and connect to remote
```bash
   mkdir ansible
   cd ansible
   git init
   git add .
   git commit -m "Initial commit of my project"
   git remote add origin <remote_repository_URL>
   git pull
   git push
```