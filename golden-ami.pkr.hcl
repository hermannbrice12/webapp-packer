packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

variable "aws_access_key" {
  type    = string
  default = env("AWS_ACCESS_KEY_ID")
}

variable "aws_secret_key" {
  type    = string
  default = env("AWS_SECRET_ACCESS_KEY")
  sensitive = true
}

data "amazon-ami" "golden-ami" {
  access_key = var.aws_access_key     
  secret_key = var.aws_secret_key 
  region     = "us-east-1"
  filters = {
    virtualization-type = "hvm"
    name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
    root-device-type    = "ebs"
  }
  owners      = ["099720109477"]
  most_recent = true
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "golden-ami" {
  access_key    = var.aws_access_key    
  secret_key    = var.aws_secret_key  
  ami_name      = "golden-ami-${local.timestamp}"
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
  sources = ["source.amazon-ebs.golden-ami"]
  provisioner "shell" {
    scripts = ["install_awscli.sh", "install_cloudwatch.sh", "install_ssm.sh"]
  }
}