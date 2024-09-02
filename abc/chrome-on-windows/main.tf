#
# Set up a Windows Server 2019 ECS instance and install 
# Chrome using a PowerShell script
#
# Author: Jeremy Pedersen
# Creation Date: 2019-03-12
# Last Updated: 2021-12-21

# Set up the "aliyun" (Alibaba Cloud) provider
provider "alicloud" {
  shared_credentials_file = "~/.aliyun/config.json"
  profile                 = "default"
  # If you don't have the Alibaba Cloud CLI installed,
  # you can use an AK Key and Secret instead (as below)
  # access_key = access_key_value
  # secret_key = secret_key_value
  region = var.region
}

# Determine what availability zones are available in our chosen region
data "alicloud_zones" "abc_zones" {}

# Find instances types available in the chosen region/availability zone
# with at least 8 GB of memory
data "alicloud_instance_types" "mem8g" {
  memory_size       = 8
  availability_zone = data.alicloud_zones.abc_zones.zones.0.id
}

# Create Windows Server ECS instance
resource "alicloud_instance" "tf_example" {
  instance_name = "tf_examples_windows2019"

  # Note: you can check https://api.aliyun.com for an updated list of 
  # image names, by running the "DescribeImages" ECS API call from
  # that page
  image_id = "win2019_64_dtc_1809_en-us_40G_alibase_20190816.vhd"

  instance_type   = data.alicloud_instance_types.mem8g.instance_types.0.id
  security_groups = ["${alicloud_security_group.tf_example.id}"]

  vswitch_id = alicloud_vswitch.tf_example.id

  password = var.password

  # Ensure we get a public IP address by choosing a non-zero Internet bandwidth
  internet_max_bandwidth_out = 10 # 10 Mbps - plenty for a demo, can be set up to 100 Mbps

  # Powershell script to install Chrome
  user_data = file("install_chrome.ps1")
}

# Set up VSwitch and VPC
resource "alicloud_vpc" "tf_example" {
  vpc_name   = "tf_examples_windows2019_vpc"
  cidr_block = var.cidr_block
}

resource "alicloud_vswitch" "tf_example" {
  vpc_id     = alicloud_vpc.tf_example.id
  cidr_block = var.cidr_block
  zone_id    = data.alicloud_zones.abc_zones.zones.0.id
}

# Set up security group
resource "alicloud_security_group" "tf_example" {
  name   = "tf_examples_windows2019"
  vpc_id = alicloud_vpc.tf_example.id
}

# Create security group rule for RDP access
resource "alicloud_security_group_rule" "tf_example_rdp" {
  type              = "ingress"
  ip_protocol       = "tcp"
  port_range        = "3389/3389"
  security_group_id = alicloud_security_group.tf_example.id
  cidr_ip           = "0.0.0.0/0"
}
