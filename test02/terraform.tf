# provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  required_version = ">= 0.14.9"
}

# Uncomment it to use Ivan's S3 for tf state OR change it to your bucket
# terraform {
#   backend "s3" {
#     bucket = "ixwongitdevopslabbucket"
#     key    = "tech-test-02.tfstate"
#     region = "ap-southeast-1"
#   }
# }

provider "aws" {
  profile = local.aws_profile
  region  = local.aws_region
}

locals {
  aws_region = "ap-southeast-1"
}

locals {
  aws_profile = "tech_test"
}

locals {
  ami_id = "ami-0cc8dc7a69cd8b547"
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "tf-test02-vpc"
  cidr = "10.1.0.0/16"

  azs            = ["ap-southeast-1a"]
  public_subnets = ["10.1.1.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "tech_test"
  }
}

resource "tls_private_key" "tf-test02-ec2-prikey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "tf-test02-ec2-key" {
  key_name   = "tf-test02-ec2-key"
  public_key = tls_private_key.tf-test02-ec2-prikey.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.tf-test02-ec2-prikey.private_key_pem}' > ./tf-test02-ec2-key.pem"
  }
}


# Security for ec2
resource "aws_security_group" "tf-test02-ec2-sg" {
  name        = "tf-test02-ec2-sg"
  description = "tf-test02-ec2-sg"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "tf-test02-ec2-sg"
  }
}

resource "aws_security_group_rule" "tf-test02-ec2-allow-ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.tf-test02-ec2-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "tf-test02-ec2-allow-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.tf-test02-ec2-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Creating EC2 instance
resource "aws_instance" "tf-test02-ec2" {
  ami                    = local.ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.tf-test02-ec2-sg.id]
  subnet_id              = element(module.vpc.public_subnets, 0)
  key_name               = aws_key_pair.tf-test02-ec2-key.key_name

  tags = {
    Name = "tf-test02-ec2"
  }
}

output "ec2-tags" {
  value = aws_instance.tf-test02-ec2.tags
}
