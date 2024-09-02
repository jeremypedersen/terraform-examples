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
  value       = "${rsadecrypt(aws_instance.ec2-chrome-on-win-instance.password_data, file(var.key_file))}"
}

output "ip" {
  description = "Public IP address of our new Windows Server instance"
  value       = "${aws_instance.ec2-chrome-on-win-instance.public_ip}"
}
