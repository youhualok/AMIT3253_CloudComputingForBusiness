# Load Balancer
resource "aws_lb" "alb" {
  name               = "${var.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public[*].id
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.name_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.this.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Auto Scaling Launch Template
resource "aws_launch_template" "lt" {
  name_prefix   = "${var.name_prefix}-lt"
  image_id      = "ami-0c101bf1116744217" # Amazon Linux 2023 in us-east-1
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd php php-mysqlnd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>TARUMT Sports Facility Booking Platform Live!</h1>" > /var/www/html/index.php
              EOF
  )
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.tg.arn]
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
}

# Output ALB DNS URL
output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}