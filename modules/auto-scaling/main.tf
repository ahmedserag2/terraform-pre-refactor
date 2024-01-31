resource "aws_lb" "alb" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.elb_sg.id]
  subnets            = var.public_sub_ids[*]

  enable_deletion_protection = false



  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"
  

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}


resource "aws_lb_target_group" "main" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}
# resource "aws_lb_target_group_attachment" "test" {
#     count = var.env == "dev" ? 1 : 2
#   target_group_arn = aws_lb_target_group.main.arn
#   target_id        = aws_instance.ec2[count.index].id
#   port             = 80
# }

resource "aws_security_group" "ec2_sg" {
  name = "instanceRules"

  vpc_id = var.vpc_id


  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.elb_sg.id]
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elb_sg" {
  name   = "albrules"
  #vpc_id = var.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

# resource "aws_instance" "ec2" {
#   count                  = var.env == "dev" ? 1 : 2
#   ami                    = "ami-053b0d53c279acc90"
#   instance_type          = "t2.micro"
#   subnet_id              = var.subnet_ids[count.index] #element(data.aws_subnet.private_sub.*.id, count.index)
#   user_data              = file("../apache.sh")
#   vpc_security_group_ids = [aws_security_group.ec2_sg.id]
#     key_name = "bastion_key"
#   tags = {
#     Name = var.env == "dev" ? "dev_instance" : "prod_instance"
#   }
# }


## 
# ASG STARTS HERE
##

resource "aws_launch_template" "launch" {
  name_prefix   = "launch"
  image_id      = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  vpc_security_group_ids  = [aws_security_group.ec2_sg.id]
  user_data              = filebase64("../apache.sh")
}

resource "aws_autoscaling_group" "asg" {
  #availability_zones = ["us-east-1a","us-east-1b"]
  desired_capacity   = var.env == "dev" ? 1 : 2
  max_size           = var.env == "dev" ? 1 : 2
  min_size           = var.env == "dev" ? 1 : 2
  target_group_arns  = [aws_lb_target_group.main.arn]
  vpc_zone_identifier= var.subnet_ids[*]

  launch_template {
    id      = aws_launch_template.launch.id
    version = "$Latest"
  }
}