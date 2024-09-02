# 
# Create a simple test environment for network speed tests
# and instance stress testing
#
# Author: Jeremy Pedersen
# Creation Date: 2020-01-14
# Last Update: 2020-01-14
provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.access_key_secret}"
  region     = "${var.region}"
  version    = "~> 2.43"
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
resource "aws_vpc" "ec2-speed-test-vpc" {

  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "ec2-speed-test-vpc"
  }
}

# Create subnet
resource "aws_subnet" "ec2-speed-test-subnet" {
  vpc_id            = "${aws_vpc.ec2-speed-test-vpc.id}"
  cidr_block        = "172.16.0.0/24"
  availability_zone = "${data.aws_availability_zones.aws_zones.names[0]}"

  map_public_ip_on_launch = true

  tags = {
    Name = "ec2-speed-test-subnet"
  }
}

###
# Internet Gateway and Routing Configuration
###

# Create internet gateway (necessary to give Internet access to non-default VPCs on AWS)
resource "aws_internet_gateway" "ec2-speed-test-internet-gw" {
  vpc_id = "${aws_vpc.ec2-speed-test-vpc.id}"

  tags = {
    Name = "ec2-speed-test-internet-gw"
  }
}

# Define route for internet traffic
resource "aws_route_table" "ec2-speed-test-route-table" {
  vpc_id = "${aws_vpc.ec2-speed-test-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ec2-speed-test-internet-gw.id}"
  }

  tags = {
    Name = "ec2-speed-test-route-table"
  }
}

# Associate the route table with our subnet
resource "aws_route_table_association" "ec2-speed-test-route-table-assoc" {
  subnet_id      = "${aws_subnet.ec2-speed-test-subnet.id}"
  route_table_id = "${aws_route_table.ec2-speed-test-route-table.id}"
}

###
# Security Group Configuration
###

# Create security group, and associate rules
resource "aws_security_group" "ec2-speed-test-sg" {
  name        = "ec2-speed-test-sg"
  description = "Allow inbound ping, SSH, and iperf traffic"
  vpc_id      = "${aws_vpc.ec2-speed-test-vpc.id}"
}

resource "aws_security_group_rule" "allow-ssh-in" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open from everywhere

  security_group_id = "${aws_security_group.ec2-speed-test-sg.id}"
}

resource "aws_security_group_rule" "allow-ping-in" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open from everywhere

  security_group_id = "${aws_security_group.ec2-speed-test-sg.id}"
}

resource "aws_security_group_rule" "allow-iperf-in" {
  type        = "ingress"
  from_port   = 5001
  to_port     = 5001
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open from everywhere

  security_group_id = "${aws_security_group.ec2-speed-test-sg.id}"
}

# Allow outbound HTTP/HTTPS out for fetching system updates and packages

resource "aws_security_group_rule" "allow-http-out" {
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open to everywhere

  security_group_id = "${aws_security_group.ec2-speed-test-sg.id}"
}


resource "aws_security_group_rule" "allow-https-out" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open to everywhere

  security_group_id = "${aws_security_group.ec2-speed-test-sg.id}"
}

###
# SSH Key Configuration
###
resource "aws_key_pair" "ec2-speed-test-ssh-key" {
  key_name   = "ec2-sped-test-ssh-key"
  public_key = "${file(var.public_key_file)}"
}


###
# EC2 Configuration
###
resource "aws_instance" "ec2-speed-test-instance" {

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  key_name = "${aws_key_pair.ec2-speed-test-ssh-key.key_name}"

  vpc_security_group_ids = ["${aws_security_group.ec2-speed-test-sg.id}"] # Ensure we have bound our security group
  subnet_id              = "${aws_subnet.ec2-speed-test-subnet.id}"       # Ensure instance is launched in the subnet we created

  user_data = "${file("install.sh")}"

  tags = {
    Name = "ec2-speed-test-instance"
  }
}
