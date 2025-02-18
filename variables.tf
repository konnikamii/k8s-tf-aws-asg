variable "vpc_cidr" {
  default = "10.101.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.101.1.0/24","10.101.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.101.3.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-central-1a", "eu-central-1b"]
}

variable "host_os" {
  description = "The host OS of the VM"
  type        = string
}

variable "key_name" {
  description = "The name of the key pair"
  type        = string  
}

variable "project_name" {
  description = "The name of the project"
  type        = string  
}