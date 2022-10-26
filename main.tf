provider "aws" {
    region = "us-east-2"
  
}
data "aws_availability_zones"  "working" {}
data "aws_ami" "latest_amazon_linux" {
  most_recent      = true
  owners           = ["137112412989"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm-2.0.20221004.0-x86_64-gp2*"]
  }
}
# Security Group
resource "aws_security_group" "web" {
  name        = "web security group"
  dynamic "ingress" {
    for_each = ["80", "443"]
    content {
        description      = "web SG"
        from_port        = ingress.value
        to_port          = ingress.value
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Web Security Group"
    Owner = "Saidi Abdulramoni"
  }
}

# Launch configuration fo ASG

resource "aws_launch_configuration" "web" {
  name_prefix   = "WebSerer-Highly-Available-LC-"
  image_id      = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web.id]
  user_data = file("user_data.sh")


  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name                 = "ASG-${aws_launch_configuration.web.name}"
  launch_configuration = aws_launch_configuration.web.name
  min_size             = 3
  max_size             = 3
  min_elb_capacity     = 3
  health_check_type    = "ELB"
  vpc_zone_identifier = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
  load_balancers       = [aws_elb.web.name]

  dynamic "tag" {
    for_each = {
        Name =  "Webserver in ASG"
        Owner = "Saidi Abdulramoni"
        TAGKEY = "TAGVALUE"
    }
    content {
        key                 = tag.key
        value               = tag.value
        propagate_at_launch = true
    }
  }

   lifecycle {
    create_before_destroy = true
  }

}

# ELB
resource "aws_elb" "web" {
    name = "WebServer-Highly-Available-ELB"
    availability_zones = [data.aws_availability_zones.working.names[0], data.aws_availability_zones.working.names[1] ]
    security_groups = [aws_security_group.web.id]
    listener {
        instance_port     = 80
        instance_protocol = "http"
        lb_port           = 80
        lb_protocol       = "http"
    }
    health_check {
        healthy_threshold   = 2
        unhealthy_threshold = 2
        timeout             = 3
        target              = "HTTP:80/"
        interval            = 10
    }
      tags = {
    Name = "WebServer-Highly-Available-ELB"
    Owner = "Saidi Abdulramoni"
  }
}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.working.names[0]
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.working.names[1]
}

output "web_loadbalancer_url" {
    value = aws_elb.web.dns_name
  
}