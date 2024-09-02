# Variables used inside main.tf
# Feel free to change these values using any of these methods:
#
# 1 - Set defaults here using "default ="
# 2 - Fill them in by hand when prompted by terraform
# 3 - Set them when running terraform, using the "-var" command line flag
#
# Keep in mind that variables.tf and also terraform's tfstate files can and do
# include sensitive information you have set in your variables, so make sure you
# are not adding these files to a Github repository or other public source control
# system! In fact I recommend against setting your password, access key, or access key
# secret in this file...supply them on the command line or as environment variables instead!

variable "access_key" {
  description = "Your Alibaba Cloud Access Key (AK Key)"
}

variable "access_key_secret" {
  description = "Your Alibaba Cloud Access Key Secret (AK Secret or Secret Key)"
}

variable "password" {
  description = "The password for Windows Remote Desktop access to your instance"
}

variable "region" {
  description = "The Alibaba Cloud region where you want to launch your instance (for example cn-hongkong or ap-southeast-1)"
  default     = "ap-southeast-1"
}

variable "cidr_block" {
  description = "CIDR block to use for the VPC group we will put our instance in"
  default     = "192.168.0.0/16"
}

variable "system_image" {
  description = "Windows Server disk image to use"
  default     = "win2019_64_dtc_1809_en-us_40G_alibase_20190816.vhd"

}
