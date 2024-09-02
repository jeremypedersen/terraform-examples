# A simple TF script that sets up Windows Server instance, then
# installs Chrome Browser using a PowerShell script
#
# Author: Jeremy Pedersen
# Creation Date: 2020-01-06
# Last Updated: 2020-01-07
#
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
data "aws_ami" "windows-server" {
  most_recent = true

  filter {
    name   = "name"
    values = ["*Windows_Server-2019-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["801119661308"] # Canonical

}

###
# VPC Configuration
###

# Create VPC
resource "aws_vpc" "ec2-ssh-on-win-vpc" {

  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "ec2-ssh-on-win-vpc"
  }
}

# Create subnet
resource "aws_subnet" "ec2-ssh-on-win-subnet" {
  vpc_id            = "${aws_vpc.ec2-ssh-on-win-vpc.id}"
  cidr_block        = "172.16.0.0/24"
  availability_zone = "${data.aws_availability_zones.aws_zones.names[0]}"

  map_public_ip_on_launch = true

  tags = {
    Name = "ec2-ssh-on-win-subnet"
  }
}

###
# Internet Gateway and Routing Configuration
###

# Create internet gateway (necessary to give Internet access to non-default VPCs on AWS)
resource "aws_internet_gateway" "ec2-ssh-on-win-internet-gw" {
  vpc_id = "${aws_vpc.ec2-ssh-on-win-vpc.id}"

  tags = {
    Name = "ec2-ssh-on-win-internet-gw"
  }
}

# Define route for internet traffic
resource "aws_route_table" "ec2-ssh-on-win-route-table" {
  vpc_id = "${aws_vpc.ec2-ssh-on-win-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ec2-ssh-on-win-internet-gw.id}"
  }

  tags = {
    Name = "ec2-ssh-on-win-route-table"
  }
}

# Associate the route table with our subnet
resource "aws_route_table_association" "ec2-ssh-on-win-route-table-assoc" {
  subnet_id      = "${aws_subnet.ec2-ssh-on-win-subnet.id}"
  route_table_id = "${aws_route_table.ec2-ssh-on-win-route-table.id}"
}

###
# Security Group Configuration
###

# Create security group, and associate rules
resource "aws_security_group" "ec2-ssh-on-win-sg" {
  name        = "ec2-example-sg"
  description = "Allow inbound ping, RDP, and HTTP/S traffic"
  vpc_id      = "${aws_vpc.ec2-ssh-on-win-vpc.id}"
}

resource "aws_security_group_rule" "allow-rdp-in" {
  type        = "ingress"
  from_port   = 3389
  to_port     = 3389
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open from everywhere

  security_group_id = "${aws_security_group.ec2-ssh-on-win-sg.id}"
}

resource "aws_security_group_rule" "allow-ssh-in" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open from everywhere

  security_group_id = "${aws_security_group.ec2-ssh-on-win-sg.id}"
}

resource "aws_security_group_rule" "allow-everything-out" {
  type        = "egress"
  from_port   = 1
  to_port     = 65535
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open from everywhere

  security_group_id = "${aws_security_group.ec2-ssh-on-win-sg.id}"
}

###
# SSH Key Configuration
#
# Note: On AWS, this key is used to decrypt the password
# that AWS auto-generates for each new Windows instance
###
resource "aws_key_pair" "ec2-ssh-on-win-ssh-key" {
  key_name   = "ec2-win-key"
  public_key = "${file(var.ssh_public_key_file)}"
}

###
# EC2 Configuration
###
resource "aws_instance" "ec2-ssh-on-win-instance" {

  ami           = "${data.aws_ami.windows-server.id}"
  instance_type = "t2.micro"

  get_password_data = true

  vpc_security_group_ids = ["${aws_security_group.ec2-ssh-on-win-sg.id}"] # Ensure we have bound our security group
  subnet_id              = "${aws_subnet.ec2-ssh-on-win-subnet.id}"       # Ensure instance is launched in the subnet we created

  key_name = "${aws_key_pair.ec2-ssh-on-win-ssh-key.key_name}"

  # Powershell script to install Chrome
  user_data = "${filebase64("install_chrome_ssh.ps1")}"

  tags = {
    Name = "ec2-ssh-on-win-instance"
  }
}
