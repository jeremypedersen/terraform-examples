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
# Creation Date: 2019-01-20
# Last Updated: 2019-01-21

# Set up provider
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.access_key_secret}"
  region     = "${var.region}"
  version    = "~> 2.45"
}

###
# Data Source Configuration
###

# Get a list of zones in our selected region
data "aws_availability_zones" "aws_zones" {
  state = "available"
}

# Fetch latest Ubuntu 18.04 (Bionic Beaver) AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical

}

###
# VPC Configuration
###

# Create VPC
resource "aws_vpc" "dev-staging-test-vpc" {

  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "dev-staging-test-vpc"
  }
}

# Configure internet connectivity for our VPC
resource "aws_internet_gateway" "dev-staging-test-gw" {
  vpc_id = "${aws_vpc.dev-staging-test-vpc.id}"

  tags = {
    Name = "dev-staging-test-gw"
  }
}

# Define route for internet traffic
resource "aws_route_table" "dev-staging-test-route-table" {
  vpc_id = "${aws_vpc.dev-staging-test-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.dev-staging-test-gw.id}"
  }

  tags = {
    Name = "dev-staging-test-route-table"
  }
}

###
# Create subnets
###
resource "aws_subnet" "dev-subnet" {
  vpc_id            = "${aws_vpc.dev-staging-test-vpc.id}"
  cidr_block        = "172.16.0.0/24"
  availability_zone = "${data.aws_availability_zones.aws_zones.names[0]}"

  map_public_ip_on_launch = true

  tags = {
    Name = "dev-subnet"
  }
}

resource "aws_subnet" "staging-subnet" {
  vpc_id            = "${aws_vpc.dev-staging-test-vpc.id}"
  cidr_block        = "172.16.1.0/24"
  availability_zone = "${data.aws_availability_zones.aws_zones.names[0]}"

  map_public_ip_on_launch = true

  tags = {
    Name = "staging-subnet"
  }
}

resource "aws_subnet" "prod-subnet" {
  vpc_id            = "${aws_vpc.dev-staging-test-vpc.id}"
  cidr_block        = "172.16.2.0/24"
  availability_zone = "${data.aws_availability_zones.aws_zones.names[0]}"

  map_public_ip_on_launch = true

  tags = {
    Name = "prod-subnet"
  }
}

resource "aws_subnet" "bastion-subnet" {
  vpc_id            = "${aws_vpc.dev-staging-test-vpc.id}"
  cidr_block        = "172.16.3.0/24"
  availability_zone = "${data.aws_availability_zones.aws_zones.names[0]}"

  map_public_ip_on_launch = true

  tags = {
    Name = "bastion-subnet"
  }
}

# Set up routes so that the bastion and production subnets can reach the internet

resource "aws_route_table_association" "bastion-subnet-route-table-assoc" {
  subnet_id      = "${aws_subnet.bastion-subnet.id}"
  route_table_id = "${aws_route_table.dev-staging-test-route-table.id}"
}

resource "aws_route_table_association" "prod-subnet-route-table-assoc" {
  subnet_id      = "${aws_subnet.prod-subnet.id}"
  route_table_id = "${aws_route_table.dev-staging-test-route-table.id}"
}

###
# Security group configuration
###

# Dev
resource "aws_security_group" "dev-sg" {
  name        = "dev-sg"
  description = "Allow inbound from bastion, outbound to staging"
  vpc_id      = "${aws_vpc.dev-staging-test-vpc.id}"
}

resource "aws_security_group_rule" "all-from-bastion" {
  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "all"
  cidr_blocks = ["${aws_subnet.bastion-subnet.cidr_block}"]

  security_group_id = "${aws_security_group.dev-sg.id}"
}

resource "aws_security_group_rule" "all-to-staging" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "all"
  cidr_blocks = ["${aws_subnet.staging-subnet.cidr_block}"]

  security_group_id = "${aws_security_group.dev-sg.id}"
}

# Staging
resource "aws_security_group" "staging-sg" {
  name        = "staging-sg"
  description = "Allow inbound from bastion and dev, outbound to production"
  vpc_id      = "${aws_vpc.dev-staging-test-vpc.id}"
}

resource "aws_security_group_rule" "all-from-bastion-and-dev" {
  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "all"
  cidr_blocks = ["${aws_subnet.bastion-subnet.cidr_block}", "${aws_subnet.dev-subnet.cidr_block}"]

  security_group_id = "${aws_security_group.staging-sg.id}"
}

resource "aws_security_group_rule" "all-to-prod" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "all"
  cidr_blocks = ["${aws_subnet.prod-subnet.cidr_block}"]

  security_group_id = "${aws_security_group.staging-sg.id}"
}

# Prod
resource "aws_security_group" "prod-sg" {
  name        = "prod-sg"
  description = "Allow inbound from bastion and staging, outbound to Internet"
  vpc_id      = "${aws_vpc.dev-staging-test-vpc.id}"
}

resource "aws_security_group_rule" "all-from-bastion-and-staging" {
  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "all"
  cidr_blocks = ["${aws_subnet.bastion-subnet.cidr_block}", "${aws_subnet.staging-subnet.cidr_block}"]

  security_group_id = "${aws_security_group.prod-sg.id}"
}

resource "aws_security_group_rule" "all-to-internet" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "all"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.prod-sg.id}"
}

# Bastion
resource "aws_security_group" "bastion-sg" {
  name        = "bastion-sg"
  description = "Allow inbound SSH from anywhere, outbound to dev, staging, production"
  vpc_id      = "${aws_vpc.dev-staging-test-vpc.id}"
}

resource "aws_security_group_rule" "ssh-from-anywhere" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.bastion-sg.id}"
}

resource "aws_security_group_rule" "all-to-dev-staging-prod" {
  type        = "egress"
  from_port   = 0
  to_port     = 65535
  protocol    = "all"
  cidr_blocks = ["${aws_subnet.dev-subnet.cidr_block}", "${aws_subnet.staging-subnet.cidr_block}", "${aws_subnet.prod-subnet.cidr_block}"]

  security_group_id = "${aws_security_group.bastion-sg.id}"
}

###
# SSH key configuration
###
resource "aws_key_pair" "dev-staging-test-ssh-key" {
  key_name   = "dev-staging-test-ssh-key"
  public_key = "${file(var.public_key_file)}"
}

###
# EC2 instance configuration
###

resource "aws_instance" "ec2-dev" {

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  key_name = "${aws_key_pair.dev-staging-test-ssh-key.key_name}"

  vpc_security_group_ids = ["${aws_security_group.dev-sg.id}"] # Ensure we have bound our security group
  subnet_id              = "${aws_subnet.dev-subnet.id}"       # Ensure instance is launched in the subnet we created

  tags = {
    Name = "ec2-dev"
  }
}

resource "aws_instance" "ec2-staging" {

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  key_name = "${aws_key_pair.dev-staging-test-ssh-key.key_name}"

  vpc_security_group_ids = ["${aws_security_group.staging-sg.id}"] # Ensure we have bound our security group
  subnet_id              = "${aws_subnet.staging-subnet.id}"       # Ensure instance is launched in the subnet we created

  tags = {
    Name = "ec2-staging"
  }
}

resource "aws_instance" "ec2-prod" {

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  key_name = "${aws_key_pair.dev-staging-test-ssh-key.key_name}"

  vpc_security_group_ids = ["${aws_security_group.prod-sg.id}"] # Ensure we have bound our security group
  subnet_id              = "${aws_subnet.prod-subnet.id}"       # Ensure instance is launched in the subnet we created

  tags = {
    Name = "ec2-prod"
  }
}

resource "aws_instance" "ec2-bastion" {

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  key_name = "${aws_key_pair.dev-staging-test-ssh-key.key_name}"

  vpc_security_group_ids = ["${aws_security_group.bastion-sg.id}"] # Ensure we have bound our security group
  subnet_id              = "${aws_subnet.bastion-subnet.id}"       # Ensure instance is launched in the subnet we created

  tags = {
    Name = "ec2-bastion"
  }
}
