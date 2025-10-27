# Public ALB -> App ASG in private subnets

# Target group  for the app (port 80)

resource "aws_lb_target_group" "app" {
    name        = substr("{var.project_name}-tg", 0, 32)
    port        = 80
    protocol    = "HTTP"
    target_type = "instance"
    vpc_id      = aws_vpc.main.id
    health_check    {   
        path                = "/"
        matcher             = "200-399"
        healthy_threshold   = 2
        unhealthy_threshold = 5
        interval            = 20
        timeout             = 5
    }
    tags = merge(local.tags, { Name = "${var.project_name}-tg"})
}

resource "aws_lb" "public" {
    name                = substr("${var.project_name}-alb", 0,32)
    internal            = false
    load_balancer_type  = "application"
    security_groups     = [aws_security_group.alb.id]
    subnets             = [for s in aws_subnet.public : s.id]
    enable_deletion_protection  = false
    tags    = merge(local.tags, { Name = "{var.project_name}-alb" }) 
}

resource "aws_lb_listener" "http" {
    load_balancer_arn   = aws_lb.public.arn 
    port                = 80
    protocol            = "HTTP"
    default_action  {
        type                = "forward"
        target_group_arn    = aws_lb_target_group.app.arn
    }
}

# Launch template for app instances
data "aws_ami" "ubuntu" {
    most_recent     = true
    owners          = ["099720109477"] # Canonical
    filter {
		name = "name"
		values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
	}
}

resource "aws_launch_template" "app" {
    name_prefix     = "${var.project_name}-lt-"
    image_id        = data.aws_ami.ubuntu.id
    instance_type   = var.app_instance_type
    key_name        = var.key_name
    vpc_security_group_ids = [aws_security_group.app.id]
    user_data       = base64encode(<<-EOT
    #!/bin/bash
    set -e
    # Simple app placeholder
    apt update
    apt install -y nginx
    echo "<h1>${var.project_name} APP - $(hostname)</h1>" >
    /usr/share/nginx/html/index.html
    system enable nginx
    system start nginx
    EOT
    )
    tag_specifications {
        resource_type = "instance"
        tags = merge(local.tags, {
            Name = "${var.project_name}-app"
            Tier = "app"
        })
    }
    tags = merge(local.tags, { Name = "${var.project_name}-lt" })
}

resource "aws_autoscaling_group" "app" {
    name                = "${var.project_name}-asg"
    desired_capacity    = var.desired_capacity
    min_size            = var.min_size
    max_size            = var.max_size
    vpc_zone_identifier = [for s in aws_subnet.app : s.id ]
    health_check_type   = "ELB" health_check_grace_period = 90
    launch_template {
        id  = aws_launch_template.app.id
        version = "$Latest"
    }
    target_group_arns = [aws_lb_target_group.app.arn]
    tag {
        key     = "Name"
        value   = "${var.project_name}-app"
        propagate_at_launch = true
    }
    lifecycle {
        create_before_destroy = true
    }
}
