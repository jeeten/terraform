provider "aws" {
    region = "us-east-1"
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {

    filter {
      name = "vpc-id"
      values = [data.aws_vpc.default.id]
    }
  
}

resource "aws_launch_template" "my-launch-tmp"{
    name = "my-launch-template"
    image_id = "ami-0453ec754f44f9a4a"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance.id]

    # user_data

    user_data = filebase64("../../code_v2024-07-29/ec2-fundamentals/ec2-user-data.sh") 
    
}

# resource "aws_launch_configuration" "my_configuration" {
#     image_id = "ami-0453ec754f44f9a4a"
#     instance_type = "t2.micro"

#     security_groups = [ aws_security_group.instance.id ]


#     user_data = <<-EOF
#         #!/bin/bash
#         # Use this for your user data (script from top to bottom)
#         # install httpd (Linux 2 version)

#         yum update -y
#         yum install -y httpd
#         systemctl start httpd
#         systemctl enable httpd
#         echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
#         EOF

    
#     lifecycle {
#       create_before_destroy = true
#     }
# }


# Default security group for instances
resource "aws_security_group" "instance" {

    name = "web"

    # inbound rule
    ingress {
    
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        security_groups  = [aws_security_group.my-alb-sg.id]
        # cidr_blocks = ["0.0.0.0/0"] 
        # cidr_blocks = aws_security_group.my-alb-sg
        # cidr_blocks = 

        # cidr_blocks = ["0.0.0.0/0"] # all possible ip address
    }
    # outbound rule
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

# resource "aws_instance" "my_instance" {
    
#     ami           = "ami-0453ec754f44f9a4a"
#     instance_type = "t2.micro"
#                             #<PROVIDER_TYPE.NAME.ATTRIBUTE>
#     vpc_security_group_ids = [aws_security_group.instance.id]
    
#     # key_name      = "my_key"
#     user_data = <<-EOF
#         #!/bin/bash
#         # Use this for your user data (script from top to bottom)
#         # install httpd (Linux 2 version)

#         yum update -y
#         yum install -y httpd
#         systemctl start httpd
#         systemctl enable httpd
#         echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
#         EOF

#     user_data_replace_on_change = true


#     tags = {
#         Name = "my-instance" # instance name
#     }

# }




resource "aws_autoscaling_group" "my_asg" {

    # launch_configuration = aws_launch_configuration.my_configuration.name
    launch_template {
      id = aws_launch_template.my-launch-tmp.id
    #   name = aws_launch_template.my-launch-tmp.name
    }
    
    vpc_zone_identifier = data.aws_subnets.default.ids

    target_group_arns = [aws_lb_target_group.my_alb_tg.arn]
    health_check_type = "ELB"
    # load_balancers = aws_alb.my-alb
    # name = "my-asg"

    min_size = 2
    max_size = 10
    # desired_capacity = 1

    # vpc_zone_identifier = aws_subnet.my_subnet.id
    # target_group_arns = [aws_lb_target_group.my_tg.arn]
    # health_check_type = "ELB"
    # # health_check_grace_period = 300
    lifecycle {
        create_before_destroy = true
    }

    tag {

      key = "Name"
      value = "my-alb"
      propagate_at_launch = true

    }
    
}


# Resouce security group for Application load balancer
resource "aws_security_group" "my-alb-sg" {
    name        = "my-alb-sg"


    #Allow inbound HTTP requests
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #Allow all outbound requests
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

# Resource for loadbalncer
resource "aws_alb" "my-alb" {
    name            = "my-alb"
    load_balancer_type = "application"
    subnets         = data.aws_subnets.default.ids
    security_groups = [aws_security_group.my-alb-sg.id]
}

# Resource for alb listener
resource "aws_alb_listener" "http" {
    load_balancer_arn = aws_alb.my-alb.arn
    port              = "80"
    protocol          = "HTTP"

    default_action {
      type = "fixed-response"
      fixed_response {
        content_type = "text/plain"
        message_body =  "404: page not found"
        status_code = 404
      }
    }
}

resource "aws_lb_listener_rule" "my-alb-listeners" {

    listener_arn = aws_alb_listener.http.arn
    priority     = 100

    condition {
      path_pattern {
        values = ["*"]
      }
    }

    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.my_alb_tg.arn
    }
  
}

resource "aws_lb_target_group" "my_alb_tg" {
    name     = "my-alb-tg"
    port     = var.server_port
    protocol = "HTTP"

    vpc_id   = data.aws_vpc.default.id

    health_check {
      path = "/"
      protocol = "HTTP" 
      matcher =  "200"
      interval = 15
      timeout = 3
      healthy_threshold = 2
      unhealthy_threshold = 2
    }
  
}

# terraform {
#     backend "s3" {
#       key    = "dev/s3/terraform.tfstate"
#       bucket = "terraform-glob-state"
#       region = "us-east-1"
#       dynamodb_table = "terraform-glob-state"
#       encrypt = true
#     }
# }

# terraform init -migrate-state
# terraform plan -out=tfplan -var-file="dev.tfvars"
# terraform init -reconfigure
