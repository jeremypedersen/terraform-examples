#
# This script sets up the infrasctructure required for running a simple CI/CD pipeline on 
# Alibaba Cloud. Ansible scripts are then run to install and configure software on top of the
# infrastructure created here.
#
# Author: Jeremy Pedersen
# Creation Date: 2019-06-27
# Last Update: 2020-02-25

provider "alicloud" {
  access_key = "${var.access_key}"
  secret_key = "${var.access_key_secret}"
  region     = "${var.region}"
  version    = "~> 1.71"

}

# Get a list of availability zones in our selected region
data "alicloud_zones" "abc_zones" {
  multi = true
}

# Get a list of mid-range instnace types we can use
# in the first zone in this region
data "alicloud_instance_types" "cores2mem4g" {
  memory_size       = 4
  cpu_core_count    = 2
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

###
# VPC and VSwitch Config
### 

resource "alicloud_vpc" "cicd-demo-vpc" {
  name       = "cicd-demo-vpc"
  cidr_block = "192.168.0.0/16"
}

resource "alicloud_vswitch" "cicd-demo-vswitch-a" {
  name              = "cicd-demo-vswitch"
  vpc_id            = "${alicloud_vpc.cicd-demo-vpc.id}"
  cidr_block        = "192.168.0.0/24"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.0.id}"
}

resource "alicloud_vswitch" "cicd-demo-vswitch-b" {
  name              = "cicd-demo-vswitch"
  vpc_id            = "${alicloud_vpc.cicd-demo-vpc.id}"
  cidr_block        = "192.168.1.0/24"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.1.id}"
}

resource "alicloud_vswitch" "cicd-demo-vswitch-c" {
  name              = "cicd-demo-vswitch"
  vpc_id            = "${alicloud_vpc.cicd-demo-vpc.id}"
  cidr_block        = "192.168.2.0/24"
  availability_zone = "${data.alicloud_zones.abc_zones.zones.2.id}"
}


###
# Security Group Config
###
resource "alicloud_security_group" "cicd-demo-sg" {
  name        = "cicd-demo-sg"
  vpc_id      = "${alicloud_vpc.cicd-demo-vpc.id}"
  description = "Web tier security group"
}

# Open access for ICMP (ping), SSH, HTTP, and HTTPS from the internet
resource "alicloud_security_group_rule" "http_in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "80/80"
  security_group_id = "${alicloud_security_group.cicd-demo-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "https_in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "443/443"
  security_group_id = "${alicloud_security_group.cicd-demo-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "ssh_in" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  security_group_id = "${alicloud_security_group.cicd-demo-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "icmp" {
  type              = "ingress"
  ip_protocol       = "icmp"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = "${alicloud_security_group.cicd-demo-sg.id}"
  cidr_ip           = "0.0.0.0/0"
}

###
# OSS Bucket Config for GitLab backups
###

# Generate a random string to ensure a unique bucket name
resource "random_pet" "bucket-name" {
  length = 3
  prefix = "gitlab-oss-bucket"
}

resource "alicloud_oss_bucket" "gitlab-oss-bucket" {
  bucket        = "${random_pet.bucket-name.id}"
  acl           = "private"
  force_destroy = "true"
}

###
# SSH Key Config
###

# SSH key pair for GitLab/SonarQube SSH login
resource "alicloud_key_pair" "cicd-ssh-key" {
  key_name = "${var.ssh_key_name}"
  key_file = "${var.ssh_key_name}.pem"
}

###
# RDS Config
###

# Create new PostgreSQL DB for SonarQube
resource "alicloud_db_instance" "sonarqube_postgres_db_instance" {
  engine           = "PostgreSQL"
  engine_version   = "10.0"
  instance_type    = "pg.n2.small.1"
  instance_storage = "20"
  instance_name    = "sonarqube-db"
  vswitch_id       = "${alicloud_vswitch.cicd-demo-vswitch-c.id}"
  security_ips     = ["${alicloud_instance.cicd-demo-sonar-ecs.private_ip}"]
}

resource "alicloud_db_account" "sonarqube_postgres_db_account" {
  instance_id = "${alicloud_db_instance.sonarqube_postgres_db_instance.id}"
  name        = "${var.sonarqube_db_username}"
  password    = "${var.sonarqube_db_password}"

  depends_on = ["alicloud_db_instance.sonarqube_postgres_db_instance"]
}

resource "alicloud_db_database" "sonarqube_postgres_db" {
  instance_id = "${alicloud_db_instance.sonarqube_postgres_db_instance.id}"
  name        = "sonarqube"
}

###
# ECS Config
###

# Create GitLab instance
resource "alicloud_instance" "cicd-demo-gitlab-ecs" {
  instance_name = "cicd-demo-gitlab-ecs"

  image_id = "${var.alicloud_image_id}"

  instance_type        = "${data.alicloud_instance_types.cores2mem4g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.cicd-demo-sg.id}"]
  vswitch_id           = "${alicloud_vswitch.cicd-demo-vswitch-a.id}"

  # SSH Key for instance login
  key_name = "${var.ssh_key_name}"

  # Make sure no public IP is assigned (we will bind an EIP instead)
  internet_max_bandwidth_out = 0
}

# Create GitLab runner instance
resource "alicloud_instance" "cicd-demo-gitlab-runner-ecs" {
  instance_name = "cicd-demo-gitlab-runner-ecs"

  image_id = "${var.alicloud_image_id}"

  instance_type        = "${data.alicloud_instance_types.cores2mem4g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.cicd-demo-sg.id}"]
  vswitch_id           = "${alicloud_vswitch.cicd-demo-vswitch-a.id}"

  # SSH Key for instance login
  key_name = "${var.ssh_key_name}"

  # Install gitlab runner and docker
  user_data = "${file("resources/configure_gitlab_runner.sh")}"

  # Make sure a public IP is assigned (with bandwidth of 10 Mbps, which should be plenty)
  internet_max_bandwidth_out = 10
}

resource "alicloud_instance" "cicd-demo-sonar-ecs" {
  instance_name = "cicd-demo-sonar-ecs"

  image_id = "${var.alicloud_image_id}"

  instance_type        = "${data.alicloud_instance_types.cores2mem4g.instance_types.0.id}"
  system_disk_category = "cloud_efficiency"
  security_groups      = ["${alicloud_security_group.cicd-demo-sg.id}"]
  vswitch_id           = "${alicloud_vswitch.cicd-demo-vswitch-a.id}"

  # SSH Key for instance login
  key_name = "${var.ssh_key_name}"

  # Make sure no public IP is assigned (we will bind an EIP instead)
  internet_max_bandwidth_out = 0
}

###
# EIP Config
###

# EIP for GitLab instance (5 Mbps bandwidth by default)
resource "alicloud_eip" "gitlab-eip" {
  name = "gitlab-eip"
}

resource "alicloud_eip_association" "gitlab-eip-assoc" {
  allocation_id = "${alicloud_eip.gitlab-eip.id}"
  instance_id   = "${alicloud_instance.cicd-demo-gitlab-ecs.id}"
}

# EIP for SonarQube instance (5 Mbps bandwidth by default)
resource "alicloud_eip" "sonar-eip" {
  name = "sonar-eip"
}

resource "alicloud_eip_association" "sonar-eip-assoc" {
  allocation_id = "${alicloud_eip.sonar-eip.id}"
  instance_id   = "${alicloud_instance.cicd-demo-sonar-ecs.id}"
}

###
# DNS Config
###

# GitLab DNS Record
resource "alicloud_dns_record" "gitlab-dns" {
  name        = "${var.domain}"
  host_record = "gitlab"
  type        = "A"
  value       = "${alicloud_eip.gitlab-eip.ip_address}"
}

# SonarQube DNS Record
resource "alicloud_dns_record" "sonar-dns" {
  name        = "${var.domain}"
  host_record = "sonar"
  type        = "A"
  value       = "${alicloud_eip.sonar-eip.ip_address}"
}

###
# DirectMail DNS Records
###

# Ownership Verification
resource "alicloud_dns_record" "directmail-ownership" {
  name        = "${var.domain}"
  host_record = "${var.dm_ownership_host_record}"
  type        = "TXT"
  value       = "${var.dm_ownership_record_value}"
}

# SPF Verification
resource "alicloud_dns_record" "directmail-spf" {
  name        = "${var.domain}"
  host_record = "${var.dm_spf_host_record}"
  type        = "TXT"
  value       = "${var.dm_spf_record_value}"
}

# MX Verification
resource "alicloud_dns_record" "directmail-mx" {
  name        = "${var.domain}"
  host_record = "${var.dm_mx_host_record}"
  type        = "MX"
  priority    = "10" # This field is required for MX records
  value       = "${var.dm_mx_record_value}"
}

# CNAME Verification
resource "alicloud_dns_record" "directmail-cname" {
  name        = "${var.domain}"
  host_record = "${var.dm_cname_host_record}"
  type        = "CNAME"
  value       = "${var.dm_cname_record_value}"
}

###
# RAM Account Config
###

# Create a new RAM user, assign the AliyunOSSFullAccess role, and generate a new 
# access key (will be used by GitLab for storing backups)
resource "alicloud_ram_user" "gitlab-demo-oss-fullaccess-user" {
  name = "gitlab-demo-oss-fullaccess-user"
}

resource "alicloud_ram_user_policy_attachment" "gitlab-demo-oss-fullaccess-policy-attachment" {
  policy_name = "AliyunOSSFullAccess"
  policy_type = "System"
  user_name   = "${alicloud_ram_user.gitlab-demo-oss-fullaccess-user.name}"
}

resource "alicloud_ram_access_key" "gitlab-demo-oss-fullaccess-ak" {
  user_name   = "${alicloud_ram_user.gitlab-demo-oss-fullaccess-user.name}"
  secret_file = "oss-fullaccess.ak"
}

# Create an additional user which will be used later when we are setting up 
# the GitLab pipeline (it will be used to deploy the infrastructure for our
# demo application, so it should have FULL ACCESS)
#
# WARNING: This is a FULLY PRIVILEGED ACCESS KEY. Share with caution and DO NOT
# COMMIT TO VERSION CONTROL
resource "alicloud_ram_user" "gitlab-demo-fullaccess-user" {
  name = "gitlab-demo-fullaccess-user"
}

resource "alicloud_ram_user_policy_attachment" "gitlab-demo-fullaccess-policy-attachment" {
  policy_name = "AdministratorAccess"
  policy_type = "System"
  user_name   = "${alicloud_ram_user.gitlab-demo-fullaccess-user.name}"
}

resource "alicloud_ram_access_key" "gitlab-demo-fullaccess-ak" {
  user_name   = "${alicloud_ram_user.gitlab-demo-fullaccess-user.name}"
  secret_file = "fullaccess.ak"
}

