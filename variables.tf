variable "project_name" {
  type        = string
  default     = "ConnectWithMe"
  description = "Application / project name"
}

variable "region" {
    description = "AWS region"
    type        = string
    default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  type        = list(string)
  default     = ["ap-southeast-1a", "ap-southeast-1b"]
  description = "Two AZs for High Availability"
}
#Fixed subnets based on diagram
variable "public_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.0.0/28", "10.0.0.16/28"]
}

variable "app_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.0.32/28", "10.0.0.48/28"]
}

variable "db_subnet_cidrs" {
  type        = list(string)
  default     = ["10.0.0.64/28", "10.0.0.80/28"]
}

variable "bastion_ssh_cidr" {
  description = "CIDR that can SSH to the bastion (your IP)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "key_name" {
  description = "Existing EC2 key pair name"
  type        = string
}

variable "app_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "bastion_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

variable "db_username" {
  type        = string
  default     = "admin"
  sensitive   = false
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_allocated_storage" {
  type    = number
  default = 10
}

variable "db_instance_class" {
  type    = string
  default = "db.t2.micro"
}


