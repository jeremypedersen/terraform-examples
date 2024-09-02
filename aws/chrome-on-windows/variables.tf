# Variables used inside main.tf
# Feel free to change these values using any of these methods:
#
# 1 - Set defaults here using "default ="
# 2 - Fill them in by hand when prompted by terraform
# 3 - Set them when running terraform, using the "-var" command line flag
# 4 - Specify a value in terraform.tfvars (file)
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

#
# Note: if you change the default key file name here, you should make sure to modify
# keysetup.sh accordingly
#
variable "key_file" {
  description = "The private key we will use to descrypt the Windows instance password data field"
  default = "ec2-key-private.pem"
}

variable "public_key_file" {
  description = "The public key"
  default = "ec2-key-public.pem"
}

variable "ssh_public_key_file" {
  description = "Public key, converted to SSH key format for use with the aws_instance resource"
  default = "ec2-ssh-key-public.key"
}

variable "region" {
  description = "The Alibaba Cloud region where you want to launch your instance (for example cn-hongkong or ap-southeast-1)"
  default     = "ap-southeast-1"
}
