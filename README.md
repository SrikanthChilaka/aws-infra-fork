# AWS INFRA

## Description
This Terraform script creates a Virtual Private Cloud (VPC) in AWS and creates 3 public and 3 private subnets in different availability zones in the same region. It also creates an Internet Gateway, public and private route tables, and a public route in the public route table. It also creates a EC2 instance with neccessary security groups
<img src="https://github.com/AbhilashGade/aws-infra/blob/main/Untitled-2022-10-25-0755%20(1).png"  title="Infra provisioned">

## Instructions

* Open the terminal and navigate to the project directory.

* Run `terraform init` to initialize the project and download necessary plugins.
* Run `terraform plan` to review the changes that will be made to your AWS infrastructure.
* Run `terraform destroy` to destroy the VPC
