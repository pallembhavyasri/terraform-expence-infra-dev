# we are storing te keypair using terraform 
resource "aws_key_pair" "vpn" {
  key_name   = "vpn"
  #we can place using file 
  # ~ windows home directory 
  #public_key = file("/c/Bhavya/openvpn.pub")
  #we can directly place the public vpn as below 
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC36SHFMl6+OFqApgetF8TNumEjIHJ0ZLfChmhraI6i1f1WpTia0vjyTTiP2e/8KLRE+nIuSX8V3rLlBaJ/VJbCxmzgxAXavoADnOvF5AEUKU6S0VTbVnYpZbcgUs8SiFOPCxRm9zY9eT7XDvUnDmKOvlltCZ5F+yneF+6uQgt2s4OaTBZHHwYuV1YkQFiaBlsD2EJLlZhTJrTy4XM9XOZAhXtKw5NMwnIfgo8Qwh0FL10oj/FM+qcjS3q3QyOaFDAaj9b6l0MQrQxHwxlKq9hxiaO0oHF+E+d3C8kSsyJrQCRu4jli6fiWDlbTDiLDVlLlaKWvGlnz/MvirJVemsoU3hGr65IZEp/QF2FQ/0pgZ/708bXCUKbXBFwLiGAMqBPBwcPjX8Cz1oZfpvykreQFI+hOCwBS1y35ACe43MA9F/qABkj9wQ+SDmMifUeKorJME/WB2kqP8EJsDh3ohWAF4SpzwuPmmqtEjlhtXp7Iu58yG1zFgJa7QMURQYz89K0= param@Chinnu"
}

#to create the vpn EC2 instance 
module "openvpn" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  key_name = aws_key_pair.vpn.key_name
  name = "${var.project_name}-${var.environment}-openvpn"

  instance_type          = "t3.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.vpn_sg_id.value]
  #convert StringList to list in terraform to get the first element, split is the func name 
  #subnet_id = element(split(",", data.aws_ssm_parameter.public_subnet_ids.value), 0) #this give 2 elements(1a,1b)-->to get first value we use element function
  #we can keep in locals and use it here as well 
  subnet_id = local.public_subnet_ids
  ami = data.aws_ami.ami_info.id 
  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-openvpn"
    }
  )
}