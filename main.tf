provider "aws" {
    profile = "default"
    region  = "us-east-1"
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "bobo" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids  = [aws_security_group.ec2-sec.id]

  user_data =  <<-EOF
                #! /bin/bash
                sudo apt-get update
                sudo apt-get install -y apache2
                sudo systemctl start apache2
                sudo systemctl enable apache2
                echo "The page was created by the user-data" > /var/www/html/index.html
  EOF
  

  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_security_group" "ec2-sec"{
    name = "terra-security"

    ingress{
        from_port = 8080
        to_port   = 8080
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

output "public_ip" {
value = aws_instance.bobo.public_ip
}