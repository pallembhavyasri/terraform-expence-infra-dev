
module "bastion" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.project_name}-${var.environment}-bastion"

  instance_type          = "t3.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.bastion_sg_id.value]
  #convert StringList to list in terraform to get the first element, split is the func name 
  #subnet_id = element(split(",", data.aws_ssm_parameter.public_subnet_ids.value), 0) #this give 2 elements(1a,1b)-->to get first value we use element function
  #we can keep in locals and use it here as well 
  subnet_id = local.public_subnet_ids
  ami = data.aws_ami.ami_info.id 
  user_data = file("bastion.sh")

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-bastion"
    }
  )
}