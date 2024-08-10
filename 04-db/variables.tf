variable "environment"{
    default = "dev"
}

variable "project_name"{
    default = "expence"
}

variable "common_tags"{
    default ={
        Project = "expence"
        Terraform= "true"
        Environment= "dev"
    }
}

variable "zone_name"{
    default = "bhavya.store"
}