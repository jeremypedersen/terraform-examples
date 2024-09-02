#
# Create a simple system to host ownCloud, an open source
# "private cloud" document management system
# 
# This script will create:
#
# 1 - A new VPC group
# 2 - A new Subnet
# 3 - An RDS database instance
# 4 - An EC2 instance
# 5 - An EIP (elastic IP) address
#
# A shellscript is then run on the EC2 instance to install ownCloud
# 
# Outputs: the script will output the public IP, username (ubuntu), and password 
# for the EC2 instance, as well as the connection string for the RDS database, the 
# database name, username, and password, all of which are needed to configure ownCloud
#
# Final configuration steps are carried out by visiting the public IP of the EC2 instance and filling
# in a username and password for an ownCloud admin user, as well as the database name, database username,
# database password, and connection string. Once those are input, everything is set up and ready to go!
#
# Recommendations: once you've finished setup, I strongly recommend installing an SSL certificate using
# Let's Encrypt. You'll need to configure a domain name and point it at the server's public IP address first.
# The best Let's Encrypt setup guide I have seen is this one from DigitalOcean: https://www.digitalocean.com/community/tutorials/how-to-secure-apache-with-let-s-encrypt-on-ubuntu-18-04
# 
# Author: Jeremy Pedersen
# Creation Date: 2020-01-28
# Last Update: 2020-01-28

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
resource "aws_vpc" "owncloud-vpc" {

  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "owncloud-vpc"
  }
}

# Configure internet connectivity for our VPC
resource "aws_internet_gateway" "owncloud-gw" {
  vpc_id = "${aws_vpc.owncloud-vpc.id}"

  tags = {
    Name = "owncloud-gw"
  }
}

# Define route for internet traffic
resource "aws_route_table" "owncloud-route-table" {
  vpc_id = "${aws_vpc.owncloud-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.owncloud-gw.id}"
  }

  tags = {
    Name = "owncloud-route-table"
  }
}

###
# Create subnets
###
resource "aws_subnet" "owncloud-subnet-a" {
  vpc_id            = "${aws_vpc.owncloud-vpc.id}"
  cidr_block        = "172.16.0.0/24"
  availability_zone = "${data.aws_availability_zones.aws_zones.names[0]}"

  map_public_ip_on_launch = false

  tags = {
    Name = "owncloud-subnet-a"
  }
}

resource "aws_subnet" "owncloud-subnet-b" {
  vpc_id            = "${aws_vpc.owncloud-vpc.id}"
  cidr_block        = "172.16.1.0/24"
  availability_zone = "${data.aws_availability_zones.aws_zones.names[1]}"

  map_public_ip_on_launch = false

  tags = {
    Name = "owncloud-subnet-b"
  }
}

# Set up route so owncloud-subnet cna reach the Internet
resource "aws_route_table_association" "owncloud-subnet-a-route-table-assoc" {
  subnet_id      = "${aws_subnet.owncloud-subnet-a.id}"
  route_table_id = "${aws_route_table.owncloud-route-table.id}"
}

# Set up route so owncloud-subnet cna reach the Internet
resource "aws_route_table_association" "owncloud-subnet-b-route-table-assoc" {
  subnet_id      = "${aws_subnet.owncloud-subnet-b.id}"
  route_table_id = "${aws_route_table.owncloud-route-table.id}"
}

###
# Security group configuration
###

# Create the security group itself
resource "aws_security_group" "owncloud-sg" {
  name        = "owncloud-sg"
  description = "Security group for ownCloud webserver"
  vpc_id      = "${aws_vpc.owncloud-vpc.id}"
}

# Inbound HTTP
resource "aws_security_group_rule" "http-inbound" {
  type        = "ingress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.owncloud-sg.id}"
}

# Outbound HTTP
resource "aws_security_group_rule" "http-outbound" {
  type        = "egress"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.owncloud-sg.id}"
}

# Inbound HTTPS
resource "aws_security_group_rule" "https-inbound" {
  type        = "ingress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.owncloud-sg.id}"
}

# Outbound HTTPS
resource "aws_security_group_rule" "https-outbound" {
  type        = "egress"
  from_port   = 443
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.owncloud-sg.id}"
}

resource "aws_security_group_rule" "ssh-inbound" {
  type        = "ingress"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.owncloud-sg.id}"
}

# Also allow ICMP (ping) traffic, for testing purposes
resource "aws_security_group_rule" "allow-ping-in" {
  type        = "ingress"
  from_port   = -1
  to_port     = -1
  protocol    = "icmp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.owncloud-sg.id}"
}

# Allow outbound DB connections
resource "aws_security_group_rule" "db-outbound" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.owncloud-db-sg.id}"

  security_group_id = "${aws_security_group.owncloud-sg.id}"
}

###
# SSH Key Configuration
###
resource "aws_key_pair" "owncloud-ssh-key" {
  key_name   = "owncloud-ssh-key"
  public_key = "${file("${var.ssh_key_name}.pub")}"
}

###
# EIP Configuration
###
resource "aws_eip" "owncloud-eip" {
  instance = "${aws_instance.owncloud-instance.id}"
  vpc      = true

  depends_on = [aws_internet_gateway.owncloud-gw]

}

###
# EC2 Configuration
###
resource "aws_instance" "owncloud-instance" {

  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"

  key_name = "${aws_key_pair.owncloud-ssh-key.key_name}"

  vpc_security_group_ids = ["${aws_security_group.owncloud-sg.id}"] # Ensure we have bound our security group
  subnet_id              = "${aws_subnet.owncloud-subnet-a.id}"     # Ensure instance is launched in the subnet we created

  user_data = "${file("install_ownCloud.sh")}"

  tags = {
    Name = "owncloud-instance"
  }
}

###
# Database configuration
###

# Database security group
resource "aws_security_group" "owncloud-db-sg" {
  name        = "owncloud-db-sg"
  description = "Security group for ownCloud DB server"
  vpc_id      = "${aws_vpc.owncloud-vpc.id}"
}

resource "aws_security_group_rule" "db-inbound" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.owncloud-sg.id}"

  security_group_id = "${aws_security_group.owncloud-db-sg.id}"
}


# Create "DB Subnet Group"
resource "aws_db_subnet_group" "owncloud-db-subnet-group" {
  name       = "owncloud-db-subnet-group"
  subnet_ids = ["${aws_subnet.owncloud-subnet-a.id}", "${aws_subnet.owncloud-subnet-b.id}"]

  tags = {
    Name = "DB Subnet Group for ownCloud"
  }
}

# Create database instance and associated database
resource "aws_db_instance" "owncloud-db-instance" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t2.micro"
  name                   = "${var.db_name}"
  username               = "${var.db_username}"
  password               = "${var.db_password}"
  parameter_group_name   = "default.mysql5.7"
  vpc_security_group_ids = ["${aws_security_group.owncloud-db-sg.id}"]
  db_subnet_group_name   = "${aws_db_subnet_group.owncloud-db-subnet-group.name}"
  skip_final_snapshot    = true
}
