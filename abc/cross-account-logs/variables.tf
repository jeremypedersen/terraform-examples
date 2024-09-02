#
# Variables used in main.tf (root)
#

###
# Account IDs
###
variable "root_uid" {
  description = "The root account's UID number"
}

variable "other_uid" {
  description = "The sub account's UID number"
}

###
# Region, subnet, and CIDR configuration
###

variable "region" {
  description = "The Alibaba Cloud region you will use (defaults to Hangzhou)"
  default     = "ap-southeast-1"
}

###
# Keys and Secrets
###

variable "root_ak" {
  description = "Access Key for root account"
}

variable "root_secret" {
  description = "Access Key Secret for root account"
}

variable "other_ak" {
  description = "Access Key for shared services account"
}

variable "other_secret" {
  description = "Access Key Secret for shared services account"
}
