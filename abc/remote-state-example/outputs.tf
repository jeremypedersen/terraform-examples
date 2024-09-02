# Output the information required to log into our new instance:
#
# 1 - Username (MS remote desktop)
# 2 - Password (MS remote desktop)
# 3 - Public IP address
output "username" {
  description = "Username for RDP login"
  value       = "administrator"
}

output "password" {
  description = "Password for RDP login"
  value       = "${var.password}"
}

output "ip" {
  description = "Public IP address of our new Windows 2016 instance"
  value       = "${alicloud_instance.tf_example.public_ip}"
}

output "vpc_name" {
  description = "Name of VPC group created by main.tf"
  value = "${alicloud_vpc.tf_example.name}"
}