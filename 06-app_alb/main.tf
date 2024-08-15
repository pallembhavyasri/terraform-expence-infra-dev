resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-${var.environment}-app-alb"
  internal           = true # true if it is private load balancer 
  load_balancer_type = "application"
  security_groups    = [data.aws_ssm_parameter.app_alb_sg_id.value]
  subnets            = split(",", data.aws_ssm_parameter.private_subnet_ids.value) # we need 2 hence used split 
  enable_deletion_protection = false

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-app-alb"
    }
  )
}


# listner is http 

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP" 

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "<h1>This is fxed response from app alb</h1>" # this response will show if VPN is connected 
      status_code  = "200"
    }
  }
}

# adding the route 53 records 
module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 3.0"

  zone_name = var.zone_name

  records = [
    {
      name    = "*.app-${var.environment}" #here we have so many components so we are keeping as * 
      type    = "A"
      allow_overwrite = true 
      alias = {
        name                   = aws_lb.app_alb.dns_name
        zone_id                = aws_lb.app_alb.zone_id
     }
    }
  ]
}
