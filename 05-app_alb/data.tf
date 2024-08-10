
data "aws_ssm_parameter" "app_alb_sg_id" {
  name = "/${var.project_name}/${var.environment}/app_alb_sg_id"
}

#since app al is in private we need to fetch the private subnet ids 
data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/${var.project_name}/${var.environment}/private_subnet_ids"
}


data "aws_ami" "ami_info"{
    most_recent = true
    owners = ["679593333241"] #ami owneer id of openvpn 

    #we can use as many filters as we want to fetch 
    filter {
        name = "name"
        values = ["OpenVPN Access Server Community Image-fe8020db-*"]

    }


}