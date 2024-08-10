
data "aws_ssm_parameter" "web_alb_sg_id" {
  name = "/${var.project_name}/${var.environment}/web_alb_sg_id"
}

#since web alb is in private we need to fetch the public subnet ids 
data "aws_ssm_parameter" "public_subnet_ids" {
  name = "/${var.project_name}/${var.environment}/public_subnet_ids"
}


