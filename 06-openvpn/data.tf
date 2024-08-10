
data "aws_ssm_parameter" "vpn_sg_id" {
  name = "/${var.project_name}/${var.environment}/vpn_sg_id"
}

data "aws_ssm_parameter" "public_subnet_ids" {
  name = "/${var.project_name}/${var.environment}/public_subnet_ids"
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