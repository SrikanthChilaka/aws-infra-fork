variable "aws_region" {
    type = string
    description = "AWS region which is closest"
    default = "us-east-1"
}

variable "aws_profile" {
    type = string
    description = "AWS working profile"
    default = "dev"
}

variable "vpc_cidr" {
    type = list(string)
    description = "The CIDR block of the VPC"
    default = ["10.0.0.0/16", "10.1.0.0/16"]
}

variable "availability_zones" {
    type = list(string)
    description = "Subnets availability zones"
    default = ["a", "b", "c"]
}

variable "vpc_name_1" {
    type = string
    description = "Name of the VPC"
    default = "vpc_1"
}

variable "vpc_name_2" {
    type = string
    description = "Name of the VPC"
    default = "vpc_2"
}

variable "public_subnet_name" {
    type = string
    description = "Name of the public subnet"
    default = "prod-public-subnet"
}

variable "private_subnet_name" {
    type = string
    description = "Name of the private subnet"
    default = "prod-private-subnet"
}

variable "gateway_name_1" {
    type = string
    description = "Name of the gateway"
    default = "internet-gateway-1"
}

variable "gateway_name_2" {
    type = string
    description = "Name of the gateway"
    default = "internet-gateway-2"
}

variable "public_rt_name" {
    type = string
    description = "Name of the public route table"
    default = "prod-public-route-table"
}

variable "private_rt_name" {
    type = string
    description = "Name of the private route table"
    default = "prod-private-route-table"
}

variable "rt_cidr" {
    type = string
    description = "The CIDR block of the route table"
    default = "0.0.0.0/0"
}

variable "subnet_prefix_1" {
    type = string
    description = "prefix of the cidr"
    default = "10.0."
}

variable "subnet_prefix_2" {
    type = string
    description = "prefix of the cidr"
    default = "10.1."
}

variable "subnet_postfix" {
    type = string
    description = "postfix of the cidr"
    default = ".0/24"
}