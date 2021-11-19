provider "aws" {
    profile = "default"
    region  = "us-east-1"
}

data "aws_vpc" "default"{
    default = true
}
data "aws_subnet_ids" "default"{
    vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "ec2-sec"{
    name = "terra-security"

    ingress{
        from_port = 80
        to_port   = 80
        protocol  = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress{
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}



resource "aws_launch_configuration" "conf" {
  name          = "web_config"
  image_id      = var.image_id
  instance_type = var.instance_type
  security_groups = [aws_security_group.ec2-sec.id]
  user_data = <<-EOF
                #! /bin/bash
                
                echo "THIS PAGE" > /var/www/html/index.html
  EOF
}

resource "aws_autoscaling_group" "auto_scale" {
  name                 = "terraform-asg-example"
  launch_configuration = aws_launch_configuration.conf.name
  min_size             = var.min_size
  max_size             = var.max_size
  vpc_zone_identifier  = data.aws_subnet_ids.default.ids
  target_group_arns     = [aws_lb_target_group.target.arn]
  health_check_type    = "ELB"

  lifecycle {
    create_before_destroy = true
  }
  tag {
      key  = "Name"
      value = "terraform-ec2"
      propagate_at_launch = true
  }
}

resource "aws_lb" "load" {
  name               = "load-lb-tf"
  internal           = false
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.default.ids
  security_groups    = [aws_security_group.ec2-sec.id]

  

  tags = {
    Environment = "dev"
  }
}

resource "aws_lb_listener" "listen" {
  load_balancer_arn = aws_lb.load.arn
  port              = "80"
  protocol          = "HTTP"
 
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target.arn
  }
}

resource "aws_lb_target_group" "target" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
      path = "/"
      protocol = "HTTP"
      matcher = 200
      interval = 15
      timeout = 3
      healthy_threshold = 2
      unhealthy_threshold = 2
  }
}
output "aws_lb" {
    value = aws_lb.load.dns_name
    description = "the domain name of the load balancer"
}
