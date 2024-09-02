# Variables used in main.tf
variable "access_key" {
    description = "Alibaba Cloud access key"
}

variable "access_key_secret" {
    description = "Alibaba Cloud access key secret"
}

variable "abc_image_id" {
    description = "Disk image ID for ECS boot disk: Ubuntu 18.x"
    default = "ubuntu_18_04_64_20G_alibase_20190624.vhd"
}

variable "region" {
    description = "Alibaba Cloud Region"
    default = "cn-huhehaote"
}