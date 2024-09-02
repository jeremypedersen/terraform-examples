# Variables used in main.tf
variable "access_key" {
  description = "AWS access key"
}

variable "access_key_secret" {
  description = "AWS access key secret"
}

variable "region" {
  description = "AWS Region"
  default     = "ap-southeast-1"
}

# The default value below matches the key name used by setup.sh and destroy.sh. If you change
# they SSH key name(s) used there, you should also change the default value here
variable "public_key_file" {
  description = "Public key file for EC2 instance login"
  default     = "ec2-example-ssh-key.pub"
}
