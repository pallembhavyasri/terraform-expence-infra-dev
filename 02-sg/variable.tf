variable "environment"{
    default = "dev"
}

variable "project_name"{
    default = "expence"
}

variable "common_tags"{
    default = {
        Project = "Expence"
        Environment = "Dev"
        Terraform = "true"
    }
}

variable "db_sg_description"{
    default = "SG for DB MYSQL instance"
}

variable "backend_sg_description"{
    default = "SG for backend instance"
}

variable "frontend_sg_description"{
    default = "SG for frontend instance"
}

variable "bastion_sg_description"{
    default = "SG for bastion instance"
}


variable "ansible_sg_description"{
    default = "SG for ansible instance"
}

variable "app_alb_sg_description"{
    default = "SG for app alb instance"
}

variable "web_alb_sg_description"{
    default = "SG for web alb instance"
}

variable "vpn_sg_description"{
    default = "SG for vpn instance"
}

variable "vpn_sg_rules"{
    default = [
        {
            from_port = 943
            to_port = 943
            protocol = "tcp"  
            cidr_blocks = ["0.0.0.0/0"]
        },
        {
            from_port = 443
            to_port = 443
            protocol = "tcp"  
            cidr_blocks = ["0.0.0.0/0"]
        },
        {
            from_port = 22
            to_port = 22
            protocol = "tcp"  
            cidr_blocks = ["0.0.0.0/0"]
        },
        {
            from_port = 1194
            to_port = 1194
            protocol = "udp"  
            cidr_blocks = ["0.0.0.0/0"]
        }
    ]
}

