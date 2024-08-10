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
        Component = "backend"
    }
}

variable "zone_name"{
    default = "bhavya.store"
}