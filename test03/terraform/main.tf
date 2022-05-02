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

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

# Security Group for ALB
resource "aws_security_group" "tf-alb-sg" {
  name        = "tf-alb-sg"
  description = "tf-alb-sg"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.tf-webapp-sg.id]
  }

  tags = {
    Name = "tf-alb-sg"
  }
}

# Security for Webapp
resource "aws_security_group" "tf-webapp-sg" {
  name        = "tf-webapp-sg"
  description = "tf-webapp-sg"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name = "tf-webapp-sg"
  }
}

resource "aws_security_group_rule" "tf-webapp-allow-ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.tf-webapp-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "tf-webapp-allow-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.tf-webapp-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "tf-webapp-allow-alb" {
  type                     = "ingress"
  from_port                = 5000
  to_port                  = 5000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.tf-webapp-sg.id
  source_security_group_id = aws_security_group.tf-alb-sg.id
}

# Security for Mongodb
resource "aws_security_group" "tf-db-sg" {
  name        = "tf-db-sg"
  description = "tf-db-sg"
  vpc_id      = data.aws_vpc.main.id

  tags = {
    Name = "tf-db-sg"
  }
}

resource "aws_security_group_rule" "tf-db-allow-db" {
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  security_group_id        = aws_security_group.tf-db-sg.id
  source_security_group_id = aws_security_group.tf-webapp-sg.id
}

resource "aws_security_group_rule" "tf-db-allow-ssh" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.tf-db-sg.id
  source_security_group_id = aws_security_group.tf-webapp-sg.id
}

resource "aws_security_group_rule" "tf-db-allow-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.tf-db-sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

# ALB Setup
resource "aws_lb" "tf-webapp-alb" {
  name               = "tf-webapp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf-alb-sg.id]
  subnets            = var.vpc_subnet_id

  enable_deletion_protection = false

  tags = {
    Name = "tf-webapp-alb"
  }
}

resource "aws_lb_target_group" "tf-webapp-alb-target-grp" {
  name     = "tf-alb-target-grp"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id

  health_check {
    path = "/healthcheck"
    port = 5000
  }
}

resource "aws_lb_listener" "tf-webapp-alb-listener" {
  load_balancer_arn = aws_lb.tf-webapp-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf-webapp-alb-target-grp.arn
  }
}

# Creating Mongodb instance
resource "aws_instance" "tf-mongodb" {
  ami                    = var.db_ami_id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.tf-db-sg.id]
  user_data              = <<EOF
#!/bin/bash
docker-compose -f /home/ec2-user/docker-compose.yml up -d
EOF
  subnet_id              = "subnet-0053c2a34cdfd907a"
  key_name               = var.db_key

  tags = {
    Name = "tf-mongodb"
  }
}

# Creating Webapp autoscaling group 
resource "aws_launch_configuration" "tf-webapp-launch-config" {
  name_prefix   = "tf-webapp-launch-config-"
  image_id      = var.ami_id
  instance_type = "t2.micro"

  user_data       = data.template_file.tf_webapp_userdata.rendered
  key_name        = var.webapp_key
  security_groups = [aws_security_group.tf-webapp-sg.id]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "tf-webapp-autoscaling-grp" {
  name                 = "tf-webapp-autoscaling-grp"
  min_size             = 2
  max_size             = 5
  launch_configuration = aws_launch_configuration.tf-webapp-launch-config.name
  vpc_zone_identifier  = var.vpc_subnet_id
  target_group_arns         = [aws_lb_target_group.tf-webapp-alb-target-grp.arn]
}

resource "aws_autoscaling_attachment" "tf-webapp-autoscaling-grp" {
  autoscaling_group_name = aws_autoscaling_group.tf-webapp-autoscaling-grp.id
  alb_target_group_arn   = aws_lb_target_group.tf-webapp-alb-target-grp.arn
}

# Set up the autoscaling policy to scale on 1000 request
resource "aws_autoscaling_policy" "tf-webapp-autoscaling-policy" {
  name                      = "tf-webapp-autoscaling-policy"
  autoscaling_group_name    = aws_autoscaling_group.tf-webapp-autoscaling-grp.name
  policy_type               = "TargetTrackingScaling"
  estimated_instance_warmup = 60
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      # resource_label = "app/${aws_lb.tf-webapp-alb.name}/${aws_lb.tf-webapp-alb.id}/targetgroup/${aws_lb_target_group.tf-webapp-alb-target-grp.name}/${aws_lb_target_group.tf-webapp-alb-target-grp.id}"
      resource_label = "${aws_lb.tf-webapp-alb.arn_suffix}/${aws_lb_target_group.tf-webapp-alb-target-grp.arn_suffix}"
    }
    target_value = 1000.0
  }
}



