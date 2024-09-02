#
# Variables used in main.tf
#
# You can set default CIDR block, region, and even 
# availability zone here if you like, but I STRONGLY
# recommend you supply your access key and secret
# either as command line arguments (using the "-var" flag)
# or via environment variables, rather than putting
# them into this file
variable "access_key" {
  description = "Your Alibaba Cloud Access Key (AK Key)"
}

variable "access_key_secret" {
  description = "Your Alibaba Cloud Access Key Secret (AK Secret or Secret Key)"
}

variable "ssh_key_name" {
  description = "The name of the SSH key to create for instance login"
  default = "bastion-host-key"
}

variable "password" {
  description = "Password for login to development, staging, and production instances"
}

variable "region" {
  description = "The Alibaba Cloud region where you want to launch your instance (for example cn-hongkong or ap-southeast-1)"
  default     = "ap-southeast-1"
}

variable "vpc_cidr_block" {
    description = "CIDR block for the new VPC group we will create"
    default = "192.168.0.0/16"
}

variable "dev_vswitch_cidr_block" {
    description = "CIDR block for development subnet inside our VPC"
    default = "192.168.1.0/24"
}

variable "staging_vswitch_cidr_block" {
    description = "CIDR block for staging subnet inside our VPC"
    default = "192.168.2.0/24"
}

variable "prod_vswitch_cidr_block" {
    description = "CIDR block for production subnet inside our VPC"
    default = "192.168.3.0/24"
}

variable "management_vswitch_cidr_block" {
    description = "A separate subnet inside the VPC which holds a bastion host"
    default = "192.168.0.0/24"
}
