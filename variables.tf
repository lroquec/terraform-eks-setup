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
  default = "devEKS"
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
  default = 3
}

variable "desired_size" {
  type    = string
  default = 2
}
variable "min_size" {
  type    = string
  default = 1
}

variable "instanceType" {
  type    = list(any)
  default = ["t4g.medium"]
}

variable "ec2_ssh_key" {
  type    = string
  default = "mykey"
}

variable "tester-ip" {
  type        = string
  description = "Public IP address from user"
}