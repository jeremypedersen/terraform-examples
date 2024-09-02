# A simple TF script that sets up an Ubuntu 18 instance, installs 
# apache, and opens ports 22 and 80 to the web (also allows inbound ICMP 
# traffic, for ping).
#
# Author: Jeremy Pedersen
# Creation Date: 2020-01-05
# Last Updated: 2020-01-06
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
resource "aws_vpc" "ec2-example-vpc" {

  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "ec2-example-vpc"
  }
}

# Create subnet
resource "aws_subnet" "ec2-example-subnet" {
  vpc_id            = "${aws_vpc.ec2-example-vpc.id}"
  cidr_block        = "172.16.0.0/24"
  availability_zone = "${data.aws_availability_zones.aws_zones.names[0]}"

  map_public_ip_on_launch = true

  tags = {
    Name = "ec2-example-subnet"
  }
}

###
# Internet Gateway and Routing Configuration
###

# Create internet gateway (necessary to give Internet access to non-default VPCs on AWS)
resource "aws_internet_gateway" "ec2-example-internet-gw" {
  vpc_id = "${aws_vpc.ec2-example-vpc.id}"

  tags = {
    Name = "ec2-example-internet-gw"
  }
}

# Define route for internet traffic
resource "aws_route_table" "ec2-example-route-table" {
  vpc_id = "${aws_vpc.ec2-example-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ec2-example-internet-gw.id}"
  }

  tags = {
    Name = "ec2-example-route-table"
  }
}

# Associate the route table with our subnet
resource "aws_route_table_association" "ec2-example-route-table-assoc" {
  subnet_id      = "${aws_subnet.ec2-example-subnet.id}"
  route_table_id = "${aws_route_table.ec2-example-route-table.id}"
}

###
# Security Group Configuration
###

# Create security group, and associate rules
resource "aws_security_group" "ec2-example-sg" {
  name        = "ec2-example-sg"
  description = "Allow inbound ping, SSH, and HTTP traffic"
  vpc_id      = "${aws_vpc.ec2-example-vpc.id}"
}

resource "aws_security_group_rule" "allow-ssh-in" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open from everywhere

  security_group_id = "${aws_security_group.ec2-example-sg.id}"
}

resource "aws_security_group_rule" "allow-ping-in" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open from everywhere

  security_group_id = "${aws_security_group.ec2-example-sg.id}"
}

resource "aws_security_group_rule" "allow-http-in" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open from everywhere

  security_group_id = "${aws_security_group.ec2-example-sg.id}"
}

resource "aws_security_group_rule" "allow-https-in" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open from everywhere

  security_group_id = "${aws_security_group.ec2-example-sg.id}"
}

resource "aws_security_group_rule" "allow-http-out" {
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open from everywhere

  security_group_id = "${aws_security_group.ec2-example-sg.id}"
}

resource "aws_security_group_rule" "allow-https-out" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"] # WARNING: Open from everywhere

  security_group_id = "${aws_security_group.ec2-example-sg.id}"
}

###
# SSH Key Configuration
###
resource "aws_key_pair" "ec2-example-ssh-key" {
  key_name   = "ec2-example-ssh-key"
  public_key = "${file(var.public_key_file)}"
}

###
# EC2 Configuration
###
resource "aws_instance" "ec2-example-instance" {

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  key_name = "${aws_key_pair.ec2-example-ssh-key.key_name}"

  vpc_security_group_ids = ["${aws_security_group.ec2-example-sg.id}"] # Ensure we have bound our security group
  subnet_id              = "${aws_subnet.ec2-example-subnet.id}"       # Ensure instance is launched in the subnet we created

  user_data = "${file("install_apache.sh")}"

  tags = {
    Name = "ec2-example-instance"
  }
}
