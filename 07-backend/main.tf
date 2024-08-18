#creating an instance 
module "backend" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.project_name}-${var.environment}-${var.common_tags.Component}"

  instance_type          = "t3.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.backend_sg_id.value]
  #convert StringList to list in terraform to get the first element, split is the func name 
  #subnet_id = element(split(",", data.aws_ssm_parameter.public_subnet_ids.value), 0) #this give 2 elements(1a,1b)-->to get first value we use element function
  #we can keep in locals and use it here as well 
  subnet_id = local.private_subnet_ids
  ami = data.aws_ami.ami_info.id 
  user_data = file("backend.sh")

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-backend"
    }
  )
}


#establishing the connection 
resource "null_resource" "backend" {
  triggers = {
    instance_id = module.backend.id # this will be triggered everytime instance is created 
  }
  
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = module.backend.private_ip
  }

  #copy the file from local to server by using below 
  provisioner "file" {
    source = "backend.sh"
    destination = "/tmp/backend.sh"
  }

  #now we need to excute using the remote exec
  provisioner "remote-exec" {
    inline = [ 
        "chmod +x /tmp/backend.sh",
        "sudo sh /tmp/backend.sh ${var.common_tags.Component} ${var.environment}"
     ]
    
  }
}

#stop the server now when the null resources is exceuted 

  resource "aws_ec2_instance_state" "backend" {
  instance_id = module.backend.id
  state       = "stopped"
  #when to trigger when null resource is exceuted 
  depends_on = [ null_resource.backend ]
}

#take the AMI from instance 

resource "aws_ami_from_instance" "backend" {
  name               = "${var.project_name}-${var.environment}-${var.common_tags.Component}"
  source_instance_id = module.backend.id
  #take AMI when server is stopped 
  depends_on = [ aws_ec2_instance_state.backend ]
}

#terminate the server 


resource "null_resource" "backend_delete" {
  triggers = {
    instance_id = module.backend.id # this will be triggered everytime instance is created 
  }
  
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = module.backend.private_ip
  }

  #now we need to excute using the remote exec
  provisioner "local-exec" {
    #terminate using aws command line 
    command = "aws ec2 terminate-instances --instance-ids ${module.backend.id}"
  }

  #this needs to terminate once AMI is created 
  depends_on = [ aws_ami_from_instance.backend ]
}

#target group with health check 
resource "aws_lb_target_group" "backend" {
  name     = "${var.project_name}-${var.environment}-backend"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value
   health_check {
    path                = "/health"
    port                = 8080
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

#launch template

resource "aws_launch_template" "backend" {
  name = "${var.project_name}-${var.environment}-backend"

 
  image_id = aws_ami_from_instance.backend.id 

  instance_initiated_shutdown_behavior = "terminate"

  instance_type = "t3.micro"
  update_default_version = true #sets the latest version to default 
  vpc_security_group_ids = [data.aws_ssm_parameter.backend_sg_id.value]

  tag_specifications {
    resource_type = "instance"

    tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-backend"
    }
  )
  }

}

#autoscaling is means instance will be added to backend module 

resource "aws_autoscaling_group" "backend" {
  name                      = "${var.project_name}-${var.environment}-backend"
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 60
  health_check_type         = "ELB"
  desired_capacity          = 1
  target_group_arns = [aws_lb_target_group.backend.arn] #adding the target group to the backend auto scaling group 
  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }
  vpc_zone_identifier       = split(",", data.aws_ssm_parameter.private_subnet_ids.value)

  instance_refresh {
    strategy = "Rolling" #one is terminated and another one created 
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  tag {
    key                 = "name"
    value               = "${var.project_name}-${var.environment}-backend"
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

resource "aws_autoscaling_policy" "backend" {
  name                   = "${var.project_name}-${var.environment}-backend"
  policy_type        = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.backend.name

target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 10.0
  }

}

#ALB listner rule 

resource "aws_lb_listener_rule" "backend" {
  listener_arn = data.aws_ssm_parameter.app_alb_listener_arn.value
  priority     = 100 #less umber will be first validated 

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    host_header {
      values = ["backend.app-${var.environment}.${var.zone_name}"]
    }
  }
}


