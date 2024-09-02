# Simple demo environment for showcasing VPC FlowLog functionality
#
# Author: Jeremy Pedersen
# Creation Date: 2019-12-11
# Last Updated: 2019-12-11
#
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.access_key_secret}"
  region     = "${var.region}"
}

data "alicloud_zones" "abc_zones" {  }

# Get a list of ECS instances with 2 CPU cores and 4GB RAM
data "alicloud_instance_types" "cores2mem8g" {
  instance_type_family = "ecs.g6" # MUST USE GEN 6 INSTANCES, ONLY THESE SUPPORT FLOWLOG
  cpu_core_count = 2
  memory_size = 8
}

# Create VPC group
resource "alicloud_vpc" "flowlog-example-vpc" {
  name       = "flowlog-example-vpc"
  cidr_block = "192.168.0.0/16"
}

# Create a vSwitch
resource "alicloud_vswitch" "flowlog-example-vswitch" {
  name              = "flowlog-example-vswitch"
  vpc_id            = "${alicloud_vpc.flowlog-example-vpc.id}"
  cidr_block        = "192.168.0.0/24"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

# Create security group for ECS instances (allows 22 inbound)
resource "alicloud_security_group" "flowlog-example-sg" {
  name        = "flowlog-example-sg"
  vpc_id      = "${alicloud_vpc.flowlog-example-vpc.id}"
  description = "Webserver security group"
}

# Create inbound rule for SSH traffic (port 22 TCP)

resource "alicloud_security_group_rule" "ssh-in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  security_group_id = "${alicloud_security_group.flowlog-example-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "icmp-in" {
  type              = "ingress"
  ip_protocol       = "icmp"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.flowlog-example-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

# Create keypair for connecting to ECS instances
resource "alicloud_key_pair" "flowlog-example-ssh-key" {
  key_name = "flowlog-example-ssh-key"
  key_file = "flowlog-example-ssh-key.pem"
}

# 
# Create ECS instances
#
resource "alicloud_instance" "flowlog-example-ecs-a" {
  instance_name = "flowlog-example-ecs-a"

  image_id = "${var.abc_image_id}"

  instance_type        = "${data.alicloud_instance_types.cores2mem8g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.flowlog-example-sg.id}"]
  vswitch_id           = "${alicloud_vswitch.flowlog-example-vswitch.id}"

  key_name = "${alicloud_key_pair.flowlog-example-ssh-key.key_name}"

  internet_max_bandwidth_out = 10 # Make sure instance IS granted a public IP
}

resource "alicloud_instance" "flowlog-example-ecs-b" {
  instance_name = "flowlog-example-ecs-b"

  image_id = "${var.abc_image_id}"

  instance_type        = "${data.alicloud_instance_types.cores2mem8g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.flowlog-example-sg.id}"]
  vswitch_id           = "${alicloud_vswitch.flowlog-example-vswitch.id}"

  key_name = "${alicloud_key_pair.flowlog-example-ssh-key.key_name}"

  internet_max_bandwidth_out = 10 # Make sure instance IS granted a public IP
}

#
# Log Store Project and Associated Log Stores
#
# N Logstores are created:
# 1 - vpc-logstore (for VPC-level FlowLog)
# 2 - vswitch-logstore (for vSwitch-level FlowLog)
# 3 - 
#
resource "alicloud_log_project" "flowlog-demo-sls-project" {
  name        = "flowlog-demo-sls-project"
  description = "Demo project for testing VPC FlowLog functionality"
}
resource "alicloud_log_store" "vpc-logstore" {
  project               = "${alicloud_log_project.flowlog-demo-sls-project.name}"
  name                  = "vpc-logstore"
  shard_count           = 3
  auto_split            = true
  max_split_shard_count = 60
  append_meta           = true
}
