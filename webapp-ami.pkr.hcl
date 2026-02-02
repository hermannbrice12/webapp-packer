packer {
  required_plugins {
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

#####################
# VARIABLES
#####################

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ecr_registry" {
  description = "ECR registry URL"
  type        = string
}

variable "ecr_login_url" {
  description = "ECR login URL"
  type        = string
}

#####################
# SOURCE AMI
#####################

data "amazon-ami" "middleware-ami" {
  filters = {
    virtualization-type = "hvm"
    name                = "middleware-ami-*"
    root-device-type    = "ebs"
  }

  owners      = ["var.aws_account_id"]
  most_recent = true
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

#####################
# BUILDER
#####################

source "amazon-ebs" "webapp-ami" {
  ami_name      = "webapp-ami-${local.timestamp}"
  instance_type = "t3.micro"
  region        = var.aws_region
  source_ami    = data.amazon-ami.middleware-ami.id
  ssh_username  = "ubuntu"

  iam_instance_profile = "packerRoleSSM"

  run_tags = {
    Name = "packer-vm"
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags = {
    project = "packer"
  }
}

#####################
# BUILD
#####################

build {
  sources = ["source.amazon-ebs.webapp-ami"]

  provisioner "shell" {
    inline = [
      "set -e",
      "aws --version",
      "docker --version",

      # Login ECR (méthode recommandée)
      "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.ecr_login_url}",

      # Lancer le conteneur
      "docker run -d --name webapp -p 80:80 --restart=always ${var.ecr_registry}"
    ]
  }
}
