# Demonstrate how to attach a RAM role to an ECS instances using Terraform
#
# The created instance has the aliyun commandline tools installed by default, and
# should be able to make calls to all "aliyun ecs" functions successfully
#
# Author: Jeremy Pedersen
# Creation Date: 2019-12-11
# Last Updated: 2019-12-18
#
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.access_key_secret}"
  region     = "${var.region}"
}

data "alicloud_zones" "abc_zones" {  }

# Get a list of ECS instances with 2 CPU cores and 4GB RAM
data "alicloud_instance_types" "cores2mem4g" {
  cpu_core_count = 2
  memory_size = 4
}

# Create VPC group
resource "alicloud_vpc" "ram-example-vpc" {
  name       = "ram-example-vpc"
  cidr_block = "192.168.0.0/16"
}

# Create a vSwitch
resource "alicloud_vswitch" "ram-example-vswitch" {
  name              = "ram-example-vswitch"
  vpc_id            = "${alicloud_vpc.ram-example-vpc.id}"
  cidr_block        = "192.168.0.0/24"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

# Create security group for ECS instances
resource "alicloud_security_group" "ram-example-sg" {
  name        = "ram-example-sg"
  vpc_id      = "${alicloud_vpc.ram-example-vpc.id}"
  description = "Webserver security group"
}

# Create inbound rule for SSH traffic (port 22 TCP)

resource "alicloud_security_group_rule" "ssh-in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  security_group_id = "${alicloud_security_group.ram-example-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

# Create inbound rule for ICMP traffic (ping)
resource "alicloud_security_group_rule" "icmp-in" {
  type              = "ingress"
  ip_protocol       = "icmp"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.ram-example-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

# Create keypair for connecting to ECS instances
resource "alicloud_key_pair" "ram-example-ssh-key" {
  key_name = "ram-example-ssh-key"
  key_file = "ram-example-ssh-key.pem"
}

# Create an ECS instance (private IP only)
resource "alicloud_instance" "ram-example-ecs" {
  instance_name = "ram-example-ecs"

  image_id = "${var.abc_image_id}"

  instance_type        = "${data.alicloud_instance_types.cores2mem4g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.ram-example-sg.id}"]
  vswitch_id           = "${alicloud_vswitch.ram-example-vswitch.id}"

  key_name = "${alicloud_key_pair.ram-example-ssh-key.key_name}"

  internet_max_bandwidth_out = 10 # Make sure instance is NOT granted a public IP
}

# Create ECS RAM Role
resource "alicloud_ram_role" "oss-fullaccess-role" {
  name     = "oss-fullaccess-role"
  document = "${file("policy/oss_fullaccess_role.json")}"
  description = "Role to grant full access to OSS"
  force = true
}

# Create RAM Policy allowing full access to OSS
resource "alicloud_ram_policy" "oss-fullaccess-policy" {
  name = "oss-fullaccess-policy"
  document = "${file("policy/oss_fullaccess_policy.json")}"
  description = "RAM Policy for full access to OSS"
  force = true
}

# Attach RAM Policy to RAM Role
resource "alicloud_ram_role_policy_attachment" "oss-fullaccess-policy-attachment" {
  policy_name = "${alicloud_ram_policy.oss-fullaccess-policy.name}"
  policy_type = "${alicloud_ram_policy.oss-fullaccess-policy.type}"
  role_name = "${alicloud_ram_role.oss-fullaccess-role.name}"
}

# Attach RAM Role to ECS Instance
resource "alicloud_ram_role_attachment" "attach" {
  role_name = "${alicloud_ram_role.oss-fullaccess-role.name}"
  instance_ids = ["${alicloud_instance.ram-example-ecs.id}"]
}