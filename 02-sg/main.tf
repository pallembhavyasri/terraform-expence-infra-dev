module "db"{
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = var.db_sg_description
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    sg_name = "DB"
    common_tags = var.common_tags
}


module "backend"{
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = var.backend_sg_description
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    sg_name = "backend"
    common_tags = var.common_tags
}


module "frontend"{
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = var.frontend_sg_description
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    sg_name = "frontend"
    common_tags = var.common_tags
}

module "bastion"{
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = var.bastion_sg_description
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    sg_name = "bastion"
    common_tags = var.common_tags
}

module "app_alb"{
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = var.app_alb_sg_description
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    sg_name = "app_alb"
    common_tags = var.common_tags
}

module "web_alb"{
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = var.web_alb_sg_description
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    sg_name = "web_alb"
    common_tags = var.common_tags
}

module "vpn"{
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_description = var.vpn_sg_description
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    sg_name = "vpn"
    common_tags = var.common_tags
    ingress_rules = var.vpn_sg_rules
}



#Adding the connection 

#DB is accepting the connection from backend,bastion, vpn

resource "aws_security_group_rule" "db_backend" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = module.backend.sg_id # source is where you are getting traffic form 
  security_group_id = module.db.sg_id #reciever ID 
}

#DB is accepting the connection from bastion

resource "aws_security_group_rule" "db_bastion" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = module.bastion.sg_id # source is where you are getting traffic form 
  security_group_id = module.db.sg_id #reciever ID 
}
#DB is accepting the connection from vpn

resource "aws_security_group_rule" "db_vpn" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id # source is where you are getting traffic form 
  security_group_id = module.db.sg_id #reciever ID 
}

#backend is accepting the connection from app_alb,bastion, vpn_ssh, vpn_http

resource "aws_security_group_rule" "backend_app_alb" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  source_security_group_id = module.app_alb.sg_id # source is where you are getting traffic form 
  security_group_id = module.backend.sg_id #reciever ID 
}

resource "aws_security_group_rule" "backend_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.bastion.sg_id # source is where you are getting traffic form 
  security_group_id = module.backend.sg_id #reciever ID 
}

resource "aws_security_group_rule" "backend_vpn_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id # source is where you are getting traffic form 
  security_group_id = module.backend.sg_id #reciever ID 
}

resource "aws_security_group_rule" "backend_vpn_http" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id # source is where you are getting traffic form 
  security_group_id = module.backend.sg_id #reciever ID 
}

#added as part of Jenkins CICD
resource "aws_security_group_rule" "backend_default_vpc" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["172.31.0.0/16"] #assume the tools instance is default VPC and keeping the IPv4
  security_group_id = module.backend.sg_id
}

#added as part of Jenkins CICD
resource "aws_security_group_rule" "frontend_default_vpc" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["172.31.0.0/16"] #assume the tools instance is default VPC and keeping the IPv4
  security_group_id = module.frontend.sg_id
}

#frontend is accepting the connection from web_alb,bastion, vpn, public

resource "aws_security_group_rule" "frontend_web_alb" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.web_alb.sg_id
  #source is where you are getting traffic form is internet here is it not there hence we are kepping the cidr block  
  security_group_id = module.frontend.sg_id #reciever ID 
}


resource "aws_security_group_rule" "frontend_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.bastion.sg_id # source is where you are getting traffic form 
  security_group_id = module.frontend.sg_id #reciever ID 
}


resource "aws_security_group_rule" "frontend_vpn" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id # source is where you are getting traffic form 
  security_group_id = module.frontend.sg_id #reciever ID 
}

# not required as we are connecting from vpn 
# resource "aws_security_group_rule" "frontend_public" {
#   type              = "ingress"
#   from_port         = 22
#   to_port           = 22
#   protocol          = "tcp"
#   cidr_blocks = ["0.0.0.0/0"]
#   #source is where you are getting traffic form is internet here is it not there hence we are kepping the cidr block  
#   security_group_id = module.frontend.sg_id #reciever ID 
# }



#public is accepting the connection from bastion

resource "aws_security_group_rule" "bastion_public" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  #source is where you are getting traffic form is internet here is it not there hence we are kepping the cidr block  
  security_group_id = module.bastion.sg_id #reciever ID 
}

#app_alb is accepting connect from vpn, bastion, FE 
resource "aws_security_group_rule" "app_alb_vpn" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.vpn.sg_id # source is where you are getting traffic form 
  security_group_id = module.app_alb.sg_id #reciever ID 
}

resource "aws_security_group_rule" "app_alb_bastion" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.bastion.sg_id # source is where you are getting traffic form 
  security_group_id = module.app_alb.sg_id #reciever ID 
}

resource "aws_security_group_rule" "app_alb_frontend" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  source_security_group_id = module.frontend.sg_id # source is where you are getting traffic form 
  security_group_id = module.app_alb.sg_id #reciever ID 
}


#web_alb is accepting connect from public, https 
resource "aws_security_group_rule" "web_alb_public" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.web_alb.sg_id
}

resource "aws_security_group_rule" "web_alb_public_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = module.web_alb.sg_id
}


