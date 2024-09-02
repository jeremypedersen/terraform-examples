#
# This script deploys a Windows 2016 instance and installs Chrome using a
# PowerShell Script. However, the *key purpose* of this script is to
# demonstrate how to use an OSS bucket as a backend to store terraform 
# state.
#
# Author: Jeremy Pedersen
# Creation Date: 2019-09-30
# Last Updated: 2019-09-30

# Set up remote backend for storing terraform state
#
# In general, it's a good idea to use an AK Key and Secret here which
# are bound to a RAM account with very limited access to your account
# (for instance, with a custom policy that limits access to *only* the OSS
# bucket where your TF state is stored)
#
# NOTE: You *cannot* use TF variables inside the "terraform {}" declaration,
# so you will need to explicitly include your AK Key and Secret here, or 
# supply them as command line arguments or environment variables (it's not
# possible to use terraform.tfvars at this time)
#
# WARNING: You need to run "terraform init" any time you make changes to this terraform {} block
terraform {
  backend "oss" {
    bucket = "jdp-tfstate-ef-test" # Name of your OSS bucket (create this by hand first, via the console)
    key = "terraform.tfstate" # Name of your state file
    region = "ap-southeast-1" # Region which your OSS bucket belongs to
    #tablestore_endpoint = "https://tfstate-instance.ap-southeast-1.ots.aliyuncs.com" # TableStore Endpoint (see Alibaba Cloud Console)
    #tablestore_table = "statelock" # Table Name (create this table yourself first, via the console)
  }
}

# Set up the "aliyun" (Alibaba Cloud) provider
provider "alicloud" {
  region     = "${var.region}"
  version    = "~> 1.60"
}

# Determine what availability zones are available in our chosen region
data "alicloud_zones" "abc_zones" {}

# Find instances types available in the chosen region/availability zone
# with at least 8 GB of memory
data "alicloud_instance_types" "mem8g" {
  memory_size       = 8
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

# Create Windows Server ECS instance
resource "alicloud_instance" "tf_example" {
  instance_name = "tf_examples_windows2016"

  image_id = "win2016_64_dtc_1607_en-us_40G_alibase_20181220.vhd"

  instance_type        = "${data.alicloud_instance_types.mem8g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency" # cheapest (standard) disk type
  security_groups      = ["${alicloud_security_group.tf_example.id}"]

  vswitch_id = "${alicloud_vswitch.tf_example.id}"

  password = "${var.password}"

  # Ensure we get a public IP address by choosing a non-zero Internet bandwidth
  internet_max_bandwidth_out = 10 # 10 Mbps - plenty for a demo, can be set up to 100 Mbps

  # Powershell script to install Chrome
  user_data = "${file("install_chrome.ps1")}"
}

# Set up VSwitch and VPC
resource "alicloud_vpc" "tf_example" {
  name       = "tf_examples_windows2016_vpc"
  cidr_block = "${var.cidr_block}"
}

resource "alicloud_vswitch" "tf_example" {
  vpc_id            = "${alicloud_vpc.tf_example.id}"
  cidr_block        = "${var.cidr_block}"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

# Set up security group
resource "alicloud_security_group" "tf_example" {
  name   = "tf_examples_windows2016"
  vpc_id = "${alicloud_vpc.tf_example.id}"
}

# Create security group rule for RDP access
resource "alicloud_security_group_rule" "tf_example_rdp" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "3389/3389"
  security_group_id = "${alicloud_security_group.tf_example.id}"
  cidr_ip           = "0.0.0.0/0"
}
