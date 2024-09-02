# 
# Create a new VPC group, and set up 3 subnets, one each for:
# - Production
# - Staging
# - Development
# 
# Set up security groups for each subnet, allowing traffic 
# flow only in one direction: development -> staging -> production
#
# Also, set up a "management" subnet with a "jump box" or "bastion host"
# that allows connections to each of the 3 other groups (prod, staging, dev)
#
# Author: Jeremy Pedersen
# Creation Date: 2019-03-14
# Last Updated: 2019-10-22

# Set up provider
provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.access_key_secret}"
  region     = "${var.region}"
  version    = "~> 1.58"
}

# Get a list of availability zones
data "alicloud_zones" "abc_zones" {}

# Get a list of cheap instance types we can use for our demo
data "alicloud_instance_types" "mem4g" {
  memory_size       = 4
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

# Create a new VPC group to hold the dev, staging, prod, and management subnets
resource "alicloud_vpc" "tf_example" {
  name       = "tf_examples_vpc"
  cidr_block = "192.168.0.0/16"
}

# Create 3 subnets (dev, staging, prod)
resource "alicloud_vswitch" "dev" {
  name              = "tf_examples_vswitch_dev"
  vpc_id            = "${alicloud_vpc.tf_example.id}"
  cidr_block        = "${var.dev_vswitch_cidr_block}"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

resource "alicloud_vswitch" "staging" {
  name              = "tf_examples_vswitch_staging"
  vpc_id            = "${alicloud_vpc.tf_example.id}"
  cidr_block        = "${var.staging_vswitch_cidr_block}"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

resource "alicloud_vswitch" "prod" {
  name              = "tf_examples_vswitch_prod"
  vpc_id            = "${alicloud_vpc.tf_example.id}"
  cidr_block        = "${var.prod_vswitch_cidr_block}"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

# Set up an extra VSwitch + subnet for a bastion host
resource "alicloud_vswitch" "management" {
  name              = "tf_examples_vswitch_management"
  vpc_id            = "${alicloud_vpc.tf_example.id}"
  cidr_block        = "${var.management_vswitch_cidr_block}"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

# Set up security groups and rules to associate with each subnet

# Development
resource "alicloud_security_group" "dev" {
  name        = "tf_examples_sg_dev"
  description = "Security group for development subnet"
  vpc_id      = "${alicloud_vpc.tf_example.id}"
}

resource "alicloud_security_group_rule" "dev_to_staging" {
  type              = "egress"
  ip_protocol       = "all"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.dev.id}"
  cidr_ip           = "${var.staging_vswitch_cidr_block}"
}

resource "alicloud_security_group_rule" "management_to_dev" {
  type              = "ingress"
  ip_protocol       = "all"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.dev.id}"
  cidr_ip           = "${var.management_vswitch_cidr_block}"
}

# Staging
resource "alicloud_security_group" "staging" {
  name        = "tf_examples_sg_staging"
  description = "Security group for staging subnet"
  vpc_id      = "${alicloud_vpc.tf_example.id}"
}

resource "alicloud_security_group_rule" "staging_to_prod" {
  type              = "egress"
  ip_protocol       = "all"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.staging.id}"
  cidr_ip           = "${var.prod_vswitch_cidr_block}"
}

resource "alicloud_security_group_rule" "dev_to_staging_2" {
  type              = "ingress"
  ip_protocol       = "all"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.staging.id}"
  cidr_ip           = "${var.dev_vswitch_cidr_block}"
}

resource "alicloud_security_group_rule" "management_to_staging" {
  type              = "ingress"
  ip_protocol       = "all"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.staging.id}"
  cidr_ip           = "${var.management_vswitch_cidr_block}"
}

# Production
resource "alicloud_security_group" "prod" {
  name        = "tf_examples_sg_production"
  description = "Security group for production subnet"
  vpc_id      = "${alicloud_vpc.tf_example.id}"
}

resource "alicloud_security_group_rule" "staging_to_prod_2" {
  type              = "ingress"
  ip_protocol       = "all"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.prod.id}"
  cidr_ip           = "${var.staging_vswitch_cidr_block}"
}

resource "alicloud_security_group_rule" "management_to_prod" {
  type              = "ingress"
  ip_protocol       = "all"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.prod.id}"
  cidr_ip           = "${var.management_vswitch_cidr_block}"
}

# Management
resource "alicloud_security_group" "management" {
  name        = "tf_examples_sg_management"
  description = "Security group for management subnet"
  vpc_id      = "${alicloud_vpc.tf_example.id}"
}

resource "alicloud_security_group_rule" "management_to_everywhere" {
  type              = "egress"
  ip_protocol       = "all"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.management.id}"
  cidr_ip           = "${var.vpc_cidr_block}"
}

resource "alicloud_security_group_rule" "internet_to_management" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  security_group_id = "${alicloud_security_group.management.id}"
  cidr_ip           = "0.0.0.0/0"
}

# Specific rules to block inbound access to the management host
# from dev, staging, and prod (needed to override the SSH "allow-all"
# rule above this one)
resource "alicloud_security_group_rule" "block_ssh_dev_to_management" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "drop"
  port_range        = "22/22"
  security_group_id = "${alicloud_security_group.management.id}"
  cidr_ip           = "${var.dev_vswitch_cidr_block}"
}

resource "alicloud_security_group_rule" "block_ssh_staging_to_management" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "drop"
  port_range        = "22/22"
  security_group_id = "${alicloud_security_group.management.id}"
  cidr_ip           = "${var.staging_vswitch_cidr_block}"
}

resource "alicloud_security_group_rule" "block_ssh_prod_to_management" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "drop"
  port_range        = "22/22"
  security_group_id = "${alicloud_security_group.management.id}"
  cidr_ip           = "${var.prod_vswitch_cidr_block}"
}

# Set up SSH keypair for instance login
resource "alicloud_key_pair" "dev-staging-test-ssh-key" {
  key_name = "${var.ssh_key_name}"
  key_file = "${var.ssh_key_name}.pem"
}

# Set up dev, staging, production, and management instances

# Development instance
resource "alicloud_instance" "tf_example_dev" {
  instance_name = "tf_examples_dev_ecs"

  image_id = "ubuntu_18_04_64_20G_alibase_20190624.vhd"

  instance_type        = "${data.alicloud_instance_types.mem4g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.dev.id}"]
  vswitch_id           = "${alicloud_vswitch.dev.id}"

  # Password for instance login
  password = "${var.password}"

  # Make sure no public IP is assigned
  internet_max_bandwidth_out = 0
}

# Staging instance
resource "alicloud_instance" "tf_example_staging" {
  instance_name = "tf_examples_staging_ecs"

  image_id = "ubuntu_18_04_64_20G_alibase_20190624.vhd"

  instance_type        = "${data.alicloud_instance_types.mem4g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.staging.id}"]
  vswitch_id           = "${alicloud_vswitch.staging.id}"

  # Password for instance login
  password = "${var.password}"

  # Make sure no public IP is assigned
  internet_max_bandwidth_out = 0
}

# Production instance
resource "alicloud_instance" "tf_example_production" {
  instance_name = "tf_examples_prod_ecs"

  image_id = "ubuntu_18_04_64_20G_alibase_20190624.vhd"

  instance_type        = "${data.alicloud_instance_types.mem4g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.prod.id}"]
  vswitch_id           = "${alicloud_vswitch.prod.id}"

  # Password for instance login
  password = "${var.password}"

  # Make sure no public IP is assigned
  internet_max_bandwidth_out = 0
}

# Management instance
resource "alicloud_instance" "tf_example_management" {
  instance_name = "tf_examples_management_ecs"

  image_id = "ubuntu_18_04_64_20G_alibase_20190624.vhd"

  instance_type        = "${data.alicloud_instance_types.mem4g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.management.id}"]
  vswitch_id           = "${alicloud_vswitch.management.id}"

  # SSH key for instance login
  key_name = "${alicloud_key_pair.dev-staging-test-ssh-key.key_name}"

  # Make sure a public IP **is** assigned (for SSH access)
  internet_max_bandwidth_out = 10
}
