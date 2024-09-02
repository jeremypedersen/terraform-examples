#
# Create a simple system to host ownCloud, an open source
# "private cloud" document management system
# 
# This script will create:
#
# 1 - A new VPC group
# 2 - A new vSwitch
# 3 - An RDS database instance
# 4 - An ECS instance
# 5 - An EIP (elastic IP) address
#
# A shellscript is then run on the ECS instance to install ownCloud
# 
# Outputs: the script will output the public IP, username (root), and password 
# for the ECS instance, as well as the connection string for the RDS database, the 
# database name, username, and password, all of which are needed to configure ownCloud
#
# Final configuration steps are carried out by visiting the public IP of the ECS instance and filling
# in a username and password for an ownCloud admin user, as well as the database name, database username,
# database password, and connection string. Once those are input, everything is set up and ready to go!
#
# Recommendations: once you've finished setup, I strongly recommend installing an SSL certificate using
# Let's Encrypt. You'll need to configure a domain name and point it at the server's public IP address first.
# The best Let's Encrypt setup guide I have seen is this one from DigitalOcean: https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04
# 
# Author: Jeremy Pedersen
# Creation Date: 2019-03-26
# Last Update: 2019-10-22

provider "alicloud" {
  access_key = var.access_key
  secret_key = var.access_key_secret
  region     = var.region
}

# Get a list of availability zones
data "alicloud_zones" "abc_zones" {}

# Get a list of mid-range instnace types we can use
# to deploy ownCloud
data "alicloud_instance_types" "mem8g" {
  memory_size       = 8
  availability_zone = data.alicloud_zones.abc_zones.zones.0.id
}

# Create a new VPC group and vSwitch
resource "alicloud_vpc" "tf_examples_doc_vpc" {
  vpc_name       = "tf_examples_doc_vpc"
  cidr_block = "192.168.0.0/16"
}

resource "alicloud_vswitch" "tf_examples_doc_vswitch" {
  vswitch_name              = "tf_examples_doc_vswitch"
  vpc_id            = alicloud_vpc.tf_examples_doc_vpc.id
  cidr_block        = "192.168.0.0/24"
  zone_id = data.alicloud_zones.abc_zones.zones.0.id
}

# Create a web security group and associated
# security group rules
resource "alicloud_security_group" "tf_examples_doc_sg" {
  name        = "tf_examples_doc_sg"
  vpc_id      = alicloud_vpc.tf_examples_doc_vpc.id
  description = "Web tier security group"
}

resource "alicloud_security_group_rule" "http_in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "80/80"
  security_group_id = alicloud_security_group.tf_examples_doc_sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "https_in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "443/443"
  security_group_id = alicloud_security_group.tf_examples_doc_sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "ssh_in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  security_group_id = alicloud_security_group.tf_examples_doc_sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "db_out" {
  type              = "egress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "3306/3306"
  security_group_id = alicloud_security_group.tf_examples_doc_sg.id
  cidr_ip           = alicloud_instance.tf_examples_doc_ecs.private_ip
}

# SSH key pair for instance login
resource "alicloud_key_pair" "owncloud-key" {
  key_pair_name = "${var.ssh_key_name}"
  key_file = "${var.ssh_key_name}.pem"
}

# Create an ECS instance, and install and 
# configure required software
resource "alicloud_instance" "tf_examples_doc_ecs" {
  instance_name = "tf_examples_doc_ecs"

  # Ubuntu 20.04 (2021-06-23 edition, latest at this time)
  image_id = "ubuntu_20_04_x64_20G_alibase_20210623.vhd"

  instance_type        = data.alicloud_instance_types.mem8g.instance_types.0.id
  system_disk_category = "cloud_efficiency"
  security_groups      = [alicloud_security_group.tf_examples_doc_sg.id]
  vswitch_id           = alicloud_vswitch.tf_examples_doc_vswitch.id

  # SSH Key for instance login
  key_name = var.ssh_key_name

  # Shellscript to install LAMP stack (minus MySQL) and the ownCloud software
  user_data = file("install_ownCloud.sh")

  # Make sure no public IP is assigned (we will bind an EIP later)
  internet_max_bandwidth_out = 0
}

# Create EIP and associate to our ECS instance
resource "alicloud_eip" "tf_examples_doc_eip" {
  address_name      = "tf_examples_doc_eip"
  bandwidth = "10"                  # 10 Mbps
}

resource "alicloud_eip_association" "tf_examples_doc_eip_assoc" {
  allocation_id = alicloud_eip.tf_examples_doc_eip.id
  instance_id   = alicloud_instance.tf_examples_doc_ecs.id
}

# Set up RDS database (needed by ownCloud software stack)
# We use MySQL 5.7 here
resource "alicloud_db_instance" "tf_examples_doc_db_instance" {
    engine = "MySQL"
    engine_version = "5.7"
    instance_type = "rds.mysql.t1.small"
    instance_storage = "20" # 20 GB
    vswitch_id = alicloud_vswitch.tf_examples_doc_vswitch.id

    # Allow access from our ECS instance
    security_ips = [alicloud_instance.tf_examples_doc_ecs.private_ip]

}

# Set up database and account
resource "alicloud_db_account" "tf_examples_doc_db_account" {
    db_instance_id = alicloud_db_instance.tf_examples_doc_db_instance.id
    account_name = var.db_username
    account_password = var.db_password
}

resource "alicloud_db_account_privilege" "tf_examples_db_account_rights" {
  instance_id = alicloud_db_instance.tf_examples_doc_db_instance.id
  account_name = var.db_username
  privilege = "ReadWrite"
  db_names = [alicloud_db_database.tf_examples_doc_db.name]

  depends_on = [alicloud_db_account.tf_examples_doc_db_account]
}

resource "alicloud_db_database" "tf_examples_doc_db" {
    instance_id = alicloud_db_instance.tf_examples_doc_db_instance.id
    name = var.db_name
    character_set = "utf8"
    description = "Database table used by ownCloud"
}
