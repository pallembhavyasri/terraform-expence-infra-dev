#creating an instance 
module "frontend" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.project_name}-${var.environment}-${var.common_tags.Component}"

  instance_type          = "t3.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.frontend_sg_id.value]
  #convert StringList to list in terraform to get the first element, split is the func name 
  #subnet_id = element(split(",", data.aws_ssm_parameter.public_subnet_ids.value), 0) #this give 2 elements(1a,1b)-->to get first value we use element function
  #we can keep in locals and use it here as well 
  subnet_id = local.public_subnet_id
  ami = data.aws_ami.ami_info.id 
  user_data = file("frontend.sh")

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-frontend"
    }
  )
}


#establishing the connection 
resource "null_resource" "frontend" {
  triggers = {
    instance_id = module.frontend.id # this will be triggered everytime instance is created 
  }
  
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = module.frontend.public_ip
  }

  #copy the file from local to server by using below 
  provisioner "file" {
    source = "frontend.sh"
    destination = "/tmp/frontend.sh"
  }

  #now we need to excute using the remote exec
  provisioner "remote-exec" {
    inline = [ 
        "chmod +x /tmp/frontend.sh",
        "sudo su /tmp/frontend.sh ${var.common_tags.Component} ${var.environment}"
     ]
    
  }
}

#stop the server now when the null resources is exceuted 

  resource "aws_ec2_instance_state" "frontend" {
  instance_id = module.frontend.id
  state       = "stopped"
  #when to trigger when null resource is exceuted 
  depends_on = [ null_resource.frontend ]
}

#take the AMI from instance 

resource "aws_ami_from_instance" "frontend" {
  name               = "${var.project_name}-${var.environment}-${var.common_tags.Component}"
  source_instance_id = module.frontend.id
  #take AMI when server is stopped 
  depends_on = [ aws_ec2_instance_state.frontend ]
}

#terminate the server 


resource "null_resource" "frontend_delete" {
  triggers = {
    instance_id = module.frontend.id # this will be triggered everytime instance is created 
  }
  
  # connection {
  #   type     = "ssh"
  #   user     = "ec2-user"
  #   password = "DevOps321"
  #   host     = module.frontend.public_ip
  # }

  #now we need to excute using the remote exec
  provisioner "local-exec" {
    #terminate using aws command line 
    command = "aws ec2 terminate-instance --instance-ids ${module.frontend.id}"
  }

  #this needs to terminate once AMI is created 
  depends_on = [ aws_ami_from_instance.frontend ]
}

#target group with health check 
resource "aws_lb_target_group" "frontend" {
  name     = "${var.project_name}-${var.environment}-frontend"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value
   health_check {
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-299"
  }
}

#launch template

resource "aws_launch_template" "frontend" {
  name = "${var.project_name}-${var.environment}-frontend"

 
  image_id = aws_ami_from_instance.frontend.id 

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t3.micro"
  update_default_version = true #sets the latest version to default 
  vpc_security_group_ids = [data.aws_ssm_parameter.frontend_sg_id.value]

  tag_specifications {
    resource_type = "instance"

    tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-frontend"
    }
  )
  }

}

#autoscaling is means instance will be added to frontend module 

resource "aws_autoscaling_group" "frontend" {
  name                      = "${var.project_name}-${var.environment}-frontend"
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 60
  health_check_type         = "ELB"
  desired_capacity          = 1 #as per traffic we can increase the capacity 
  target_group_arns = [aws_lb_target_group.frontend.arn] #adding the target group to the frontend auto scaling group 
  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }
  vpc_zone_identifier       = split(",", data.aws_ssm_parameter.public_subnet_ids.value)

  instance_refresh {
    strategy = "Rolling" #one is terminated and another one created 
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  tag {
    key                 = "name"
    value               = "${var.project_name}-${var.environment}-frontend"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }

  tag {
    key                 = "Project"
    value               = "${var.project_name}"
    propagate_at_launch = false
  }
}

#autoscalling policy for CPU utilization

resource "aws_autoscaling_policy" "frontend" {
  name                   = "${var.project_name}-${var.environment}-frontend"
  policy_type        = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.frontend.name

target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 10.0
  }

}

#ALB listner rule 

resource "aws_lb_listener_rule" "frontend" {
  listener_arn = data.aws_ssm_parameter.web_alb_listener_arn_https.value #we are getting value from parameters from web alb 
  priority     = 100 #less umber will be first validated 

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = ["web-${var.environment}.${var.zone_name}"]
    }
  }
}


