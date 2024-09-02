# A simple TF script that sets up an Ubuntu 18 instance, installs 
# apache, and opens port 80.
#
# Author: Jeremy Pedersen
# Creation Date: 2019-09-21
# Last Updated: 2019-10-27
#
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.access_key_secret}"
  region     = "${var.region}"
  version    = "~> 1.58"
}

data "alicloud_zones" "abc_zones" {}

data "alicloud_instance_types" "cores2mem4g" {
  memory_size       = 4
  cpu_core_count    = 2
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

resource "alicloud_vpc" "ecs-example-vpc" {
  name       = "ecs-example-vpc"
  cidr_block = "192.168.0.0/16"
}

resource "alicloud_vswitch" "ecs-example-vswitch" {
  name              = "ecs-example-vswitch"
  vpc_id            = "${alicloud_vpc.ecs-example-vpc.id}"
  cidr_block        = "192.168.0.0/24"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

resource "alicloud_security_group" "ecs-example-sg" {
  name        = "ecs-example-sg"
  vpc_id      = "${alicloud_vpc.ecs-example-vpc.id}"
  description = "Webserver security group"
}

resource "alicloud_security_group_rule" "http-in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "80/80"
  security_group_id = "${alicloud_security_group.ecs-example-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "ssh-in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  security_group_id = "${alicloud_security_group.ecs-example-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "icmp-in" {
  type              = "ingress"
  ip_protocol       = "icmp"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.ecs-example-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_key_pair" "ecs-example-ssh-key" {
  key_name = "ecs-example-ssh-key"
  key_file = "ecs-example-ssh-key.pem"
}

resource "alicloud_instance" "ecs-example-instance" {
  instance_name = "ecs-example-instance"

  image_id = "${var.abc_image_id}"

  instance_type        = "${data.alicloud_instance_types.cores2mem4g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.ecs-example-sg.id}"]
  vswitch_id           = "${alicloud_vswitch.ecs-example-vswitch.id}"

  user_data = "${file("install_apache.sh")}"

  key_name = "${alicloud_key_pair.ecs-example-ssh-key.key_name}"

  internet_max_bandwidth_out = 10
}
