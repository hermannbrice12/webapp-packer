packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = "~> 1"
    }
  }
}

variable "aws_access_key" {
  sensitive = true
  type      = string
  default   = "fake"
}

variable "aws_secret_key" {
  sensitive = true
  type      = string
  default   = "fake"
}

variable "ecr_login_url" {
  sensitive = true
  type      = string
  default   = "fake"
}

variable "ecr_registry" {
  sensitive = false
  type      = string
  default   = "fake"
}


source "docker" "webapp-docker" {
  image  = "ubuntu:20.04"
  commit = true
  changes = [
    "EXPOSE 80",
    "LABEL maintainer='ULRICH MONJI'",
    "ENTRYPOINT [\"/usr/sbin/nginx\", \"-g\", \"daemon off;\"]",
    "CMD []"
  ]
}

build {
  name = "webapp-docker"
  sources = [
    "source.docker.webapp-docker"
  ]
  provisioner "shell" {
    inline = [
      "apt-get update",
      "sleep 30",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y nginx git",
      "rm -Rf /var/www/html/*",
      "git clone https://github.com/diranetafen/static-website-example.git /var/www/html/",
    ]
  }
  post-processors {
    post-processor "docker-tag" {
      repository = var.ecr_registry
      tag        = ["1.0", "latest"]
    }
    post-processor "docker-push" {
      ecr_login      = true
      aws_access_key = var.aws_access_key
      aws_secret_key = var.aws_secret_key
      login_server   = var.ecr_login_url
    }
  }
}

