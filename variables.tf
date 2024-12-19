variable "project_name" {
  description = "The name of the project"
  type        = string

}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "The VPC CIDR block is not a valid CIDR block"
  }
}

variable "subnet_config" {
  type = map(object({
    cidr_block = string
    public     = optional(bool, false)
  }))

  default = {
    subnet1 = {
      cidr_block = "10.0.1.0/24"
      public     = true
    }
    subnet2 = {
      cidr_block = "10.0.2.0/24"
      public     = true
    }
    subnet3 = {
      cidr_block = "10.0.3.0/24"
      public     = false
    }
    subnet4 = {
      cidr_block = "10.0.4.0/24"
      public     = false
    }
  }

  validation {
    condition = alltrue([
      for config in values(var.subnet_config) : can(cidrnetmask(config.cidr_block))
    ])
    error_message = "The cidr_block config option must contain a valid CIDR block."
  }
}

variable "eksIAMRole" {
  type    = string
  default = "devEKSCluster"
}

variable "EKSClusterName" {
  type    = string
  default = "dev-cluster"
}

variable "k8sVersion" {
  type    = string
  default = "1.30"
}

variable "workerNodeIAM" {
  type    = string
  default = "devWorkerNodes"
}

variable "max_size" {
  type    = string
  default = 2
}

variable "desired_size" {
  type    = string
  default = 1
}
variable "min_size" {
  type    = string
  default = 1
}

variable "instanceType" {
  type    = list(any)
  default = ["t3.medium"]
}

# VPC Database Subnets
variable "vpc_database_subnets" {
  description = "VPC Database Subnets"
  type        = list(string)
  default     = ["10.0.151.0/24", "10.0.152.0/24"]
}

# VPC Create Database Subnet Group (True / False)
variable "vpc_create_database_subnet_group" {
  description = "VPC Create Database Subnet Group"
  type        = bool
  default     = true
}

# VPC Create Database Subnet Route Table (True or False)
variable "vpc_create_database_subnet_route_table" {
  description = "VPC Create Database Subnet Route Table"
  type        = bool
  default     = true
}

variable "admin_user_name" {
  description = "The name of the admin user"
  type        = string
}

variable "region" {
  description = "The region in which the resources will be created"
  type        = string
  default     = "us-east-1"
  
}