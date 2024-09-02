# Variables referenced in main.tf
# 
# Note: DO NOT SAVE sensitive information here such as Access Keys or passwords. 
# Instead, supply these as shell environment variables, use the "-var" flag to supply them 
# on the command line, or set up a 'terraform.tfvars' file in this directory and add *.tfvars 
# to your .gitignore file to ensure it isn't accidentally leaked to version control
#
variable "access_key" {
  # No default, must be provided on command line or via environment variable
  description = "Alibaba Cloud Access Key ID"
}

variable "access_key_secret" {
  # No default, must be provided on command line or via environment variable
  description = "Alibaba Cloud Access Key Secret"
}

# OS Version (Disk Image ID) to use
variable "alicloud_image_id" {
  description = "Disk image to use when creating new ECS instances"
  default     = "ubuntu_18_04_x64_20G_alibase_20191225.vhd"
}

# SSH key for ECS instance login (GitLab host and SonarQube host)
variable "ssh_key_name" {
  description = "ECS SSH Key name (for login to GitLab and SonarQube machines)"
  default     = "cicd-demo-ssh-key"
}

variable "sonarqube_db_password" {
  description = "Database password for SonarQube DB account"
}

variable "sonarqube_db_username" {
  description = "Username for SonarQube DB account"
}

# Set default region to Singapore (ap-southeast-1)
# WARNING: If you change this, be aware that it could complicate the 
# configuration of DirectMail, which is only available in the Hangzhou,
# Singapore, and Sydney regions at this time (as of July 2019). 
variable "region" {
  description = "Region in which to deploy resources (RDS, ECS, EIP) - set to Singapore by default"
  default     = "ap-southeast-1"
}

# Registered domain name where applications will be hosted
# The script assumes the domain was PURCHASED USING ALIBABA
# CLOUD and will be CONFIGURED USING ALIBABA CLOUD DNS
variable "domain" {
  description = "The domain name where you will host your application"
}

# DNS Records for DirectMail

# TXT record from "1,Ownership Verification" section of DirectMail console
variable "dm_ownership_host_record" {
  description = "Host record from '1,Ownership Verification' section of DirectMail configuration"
}

variable "dm_ownership_record_value" {
  description = "Record value from '1,Ownership Verification' section of DirectMail configuration"
}

# TXT record from "2,PF Verification" section of DirectMail console

variable "dm_spf_host_record" {
  description = "Host record from '2,SPF Verification' section of DirectMail configuration"
}

variable "dm_spf_record_value" {
  description = "Record value from '1,SPF Verification' section of DirectMail configuration"
}

# MX record from "3,MX Record Verficiation" section of DirectMail console
variable "dm_mx_host_record" {
  description = "Host record from '3,MX Record Verification' section of DirectMail configuration"
}

variable "dm_mx_record_value" {
  description = "Record value from '3,MX Record Verification' section of DirectMail configuration"
}

# CNAME record from "4,CNAME Record Verification" section of DirectMail console
variable "dm_cname_host_record" {
  description = "Host record from '4,CNAME Record Verification' section of DirectMail configuration"
}

variable "dm_cname_record_value" {
  description = "Record value from '4,CNAME Record Verification' section of DirectMail configuration"
}

#
# Additional DirectMail Settings
#
variable "directmail_email" {
  description = "DirectMail email address from the 'Sender Addresses' section of the DirectMail console"
}

variable "email_address" {
  description = "Email address to be used as the contact point for LetsEncrypt certificate registration"
}

variable "directmail_smtp_address" {
  description = "SMTP endpoint (from DirectMail console)"
}
