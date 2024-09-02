#
# Variables used in main.tf
#
# You can set default CIDR block, region, and even 
# availability zone here. That said, I STRONGLY
# recommend you supply your access key and secret
# some other way. Possibilities include:
# 1) As entries in a .tfvars file (add a line to your .gitignore to make sure you don't
#    commit this to version control!!!)
# 2) Provide them on the command line using terraform's "-var" flag
# 3) Provide your Access Key and Secret as environment variables
variable "access_key" {
  description = "Your Alibaba Cloud Access Key (AK Key)"
}

variable "access_key_secret" {
  description = "Your Alibaba Cloud Access Key Secret (AK Secret or Secret Key)"
}

variable "ssh_key_name" {
  description = "An SSH key (must exist already in the region you plan to use)"
  default = "speed-test"
}

variable "region" {
  description = "The Alibaba Cloud region where you want to launch your instance (ap-southeast-1 = Singapore)"
  default     = "ap-southeast-1"
}

variable "vpc_cidr_block" {
    description = "CIDR block for the new VPC group we will create"
    default = "192.168.0.0/16"
}

variable "vswitch_cidr_block" {
    description = "CIDR block for development subnet inside our VPC"
    default = "192.168.0.0/24"
}

variable "os_type" {
  description = "Operating System disk image to use, defaults to Ubuntu 18.04"
  default = "ubuntu_18_04_64_20G_alibase_20190624.vhd"
}
