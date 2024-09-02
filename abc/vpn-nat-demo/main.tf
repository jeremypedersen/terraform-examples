# Create a simple demo environment to demonstrate NAT Gateway and VPN
# Gateway Functionality. The environment consists of:
#
# 1x ECS Instance (private IP only)
# 1x VPC group
# 1x vSwitch
# 1x NAT Gateway
# 1x VPN Gateway (SSL)
#
# This example code demonstrates how you can create a secure environment
# in which no ECS instance has a public IP, but all can be accessed over 
# SSH (via the VPN Gateway) and can reach out to the Internet for updates
# (via the NAT Gateway)
#
# Author: Jeremy Pedersen
# Creation Date: 2019-12-10
# Last Updated: 2021-01-26
#
provider "alicloud" {
  access_key = var.access_key
  secret_key = var.access_key_secret
  region     = var.region
}

data "alicloud_zones" "abc_zones" {  }

# Get a list of ECS instances with 2 CPU cores and 4GB RAM
data "alicloud_instance_types" "cores2mem4g" {
  cpu_core_count = 2
  memory_size = 4
}

# Create VPC group
resource "alicloud_vpc" "vpn-nat-example-vpc" {
  name       = "vpn-nat-example-vpc"
  cidr_block = "192.168.0.0/16"
}

# Create a vSwitch
resource "alicloud_vswitch" "vpn-nat-example-vswitch" {
  name              = "vpn-nat-example-vswitch"
  vpc_id            = alicloud_vpc.vpn-nat-example-vpc.id
  cidr_block        = "192.168.0.0/24"
  availability_zone = data.alicloud_zones.abc_zones.zones.0.id
}

# Create security group for ECS instances
resource "alicloud_security_group" "vpn-nat-example-sg" {
  name        = "vpn-nat-example-sg"
  vpc_id      = alicloud_vpc.vpn-nat-example-vpc.id
  description = "Webserver security group"
}

# Create inbound rule for SSH traffic (port 22 TCP)

resource "alicloud_security_group_rule" "ssh-in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  security_group_id = alicloud_security_group.vpn-nat-example-sg.id
  cidr_ip           = "0.0.0.0/0"
}

# Create inbound rule for ICMP traffic (ping)
resource "alicloud_security_group_rule" "icmp-in" {
  type              = "ingress"
  ip_protocol       = "icmp"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = alicloud_security_group.vpn-nat-example-sg.id
  cidr_ip           = "0.0.0.0/0"
}

# Create keypair for connecting to ECS instances
resource "alicloud_key_pair" "vpn-nat-example-ssh-key" {
  key_name = "vpn-nat-example-ssh-key"
  key_file = "vpn-nat-example-ssh-key.pem"
}

#
# Create external network connection interfaces for testing purposes
#
# 1 - VPN Gateway (inbound private traffic)
# 2 - NAT Gateway (outbound internet traffic)
#
resource "alicloud_vpn_gateway" "vpn-nat-example-vpn-gateway" {
  name                 = "vpn-nat-example-vpn-gateway"
  vpc_id               = alicloud_vpc.vpn-nat-example-vpc.id
  bandwidth            = "10"
  enable_ssl           = true
  instance_charge_type = "PostPaid" # WARNING: This must be changed to PrePaid when using aliyun.com
  description          = "vpn-nat-example-vpn-gateway"
}

# VPN Configuration (VPN Server, Client Cert)
resource "alicloud_ssl_vpn_server" "vpn-nat-ssl-vpn-server" {
  name = "vpn-nat-ssl-vpn-server"
  vpn_gateway_id = alicloud_vpn_gateway.vpn-nat-example-vpn-gateway.id
  client_ip_pool = "10.0.0.0/16"
  local_subnet = alicloud_vpc.vpn-nat-example-vpc.cidr_block
}

resource "alicloud_ssl_vpn_client_cert" "vpn-nat-ssl-vpn-client-cert" {
  name = "vpn-nat-ssl-vpn-client-cert"
  ssl_vpn_server_id = alicloud_ssl_vpn_server.vpn-nat-ssl-vpn-server.id
}

resource "alicloud_nat_gateway" "vpn-nat-example-nat-gateway" {
  vpc_id = alicloud_vpc.vpn-nat-example-vpc.id
  specification = "Small"
  name   = "vpn-nat-example-nat-gateway"
}

# EIP and EIP binding for NAT Gateway
resource "alicloud_eip" "vpn-nat-example-nat-gateway-eip" {
  name = "vpn-nat-example-nat-gateway-eip"
}

resource "alicloud_eip_association" "vpn-nat-example-nat-gateway-eip-assoc" {
  allocation_id = alicloud_eip.vpn-nat-example-nat-gateway-eip.id
  instance_id   = alicloud_nat_gateway.vpn-nat-example-nat-gateway.id
}

# Outbound (SNAT) entry
resource "alicloud_snat_entry" "vpn-nat-example-snat-entry" {
  snat_table_id     =  alicloud_nat_gateway.vpn-nat-example-nat-gateway.snat_table_ids
  source_vswitch_id = alicloud_vswitch.vpn-nat-example-vswitch.id
  snat_ip           = join(",", alicloud_eip.vpn-nat-example-nat-gateway-eip.*.ip_address)
}

# Create an ECS instance (private IP only)
resource "alicloud_instance" "vpn-nat-example-ecs" {
  instance_name = "vpn-nat-example-ecs"

  image_id = var.abc_image_id

  instance_type        = data.alicloud_instance_types.cores2mem4g.instance_types.0.id
  system_disk_category = "cloud_efficiency"
  security_groups      = [alicloud_security_group.vpn-nat-example-sg.id]
  vswitch_id           = alicloud_vswitch.vpn-nat-example-vswitch.id

  key_name = alicloud_key_pair.vpn-nat-example-ssh-key.key_name

  internet_max_bandwidth_out = 0 # Make sure instance is NOT granted a public IP
}

resource "alicloud_instance" "vpn-nat-example-ecs-public-ip" {
  instance_name = "vpn-nat-example-ecs"

  image_id = var.abc_image_id

  instance_type        = data.alicloud_instance_types.cores2mem4g.instance_types.0.id
  system_disk_category = "cloud_efficiency"
  security_groups      = [alicloud_security_group.vpn-nat-example-sg.id]
  vswitch_id           = alicloud_vswitch.vpn-nat-example-vswitch.id

  key_name = alicloud_key_pair.vpn-nat-example-ssh-key.key_name

  internet_max_bandwidth_out = 10 # Make sure instance is NOT granted a public IP
}
