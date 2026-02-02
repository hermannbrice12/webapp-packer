packer {
  required_plugins {
    ansible = {
      version = "~> 1"
      source  = "github.com/hashicorp/ansible"
    }
  }
}

variable "aws_account_id" {
  sensitive = true
  type      = string
  default   = "fake"
}
data "amazon-ami" "golden-ami" {
  filters = {
    virtualization-type = "hvm"
    name                = "golden-ami-*"
    root-device-type    = "ebs"
  }
  owners      = ["var.aws_account_id"]
  most_recent = true
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "middleware-ami" {
  ami_name      = "middleware-ami-${local.timestamp}"
  instance_type = "t3.micro"
  region        = "us-east-1"
  source_ami    = data.amazon-ami.golden-ami.id
  ssh_username  = "ubuntu"
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

build {
  sources = ["source.amazon-ebs.middleware-ami"]

  provisioner "shell" {
    inline = [
      "sudo apt-get update -y",
      "sudo apt-get install -y python3 python3-apt"
    ]
  }

  provisioner "ansible" {
    playbook_file = "install_docker.yml"
    galaxy_file   = "requirements.yml"

    ansible_env_vars = [
      "ANSIBLE_HOST_KEY_CHECKING=False","ANSIBLE_NOCOLOR=True"
    ]
  }
}
