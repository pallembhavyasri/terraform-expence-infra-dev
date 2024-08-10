data "aws_ssm_parameter" "bastion_sg_id" {
  name = "/${var.project_name}/${var.environment}/bastion_sg_id"
}

data "aws_ssm_parameter" "public_subnet_ids" {
  name = "/${var.project_name}/${var.environment}/public_subnet_ids"
}


data "aws_ami" "ami_info"{
    most_recent = true
    owners = ["973714476881"] #ami owneer id

    #we can use as many filters as we want to fetch 
    filter {
        name = "name"
        values = ["RHEL-9-DevOps-Practice"]

    }

}