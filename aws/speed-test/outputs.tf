#
# Output the information required to test the
# environment created in main.tf
#
# - Username for instance
# - Public IP address for instance
# - SSH key name (for instance login)
#
output "ssh_key_name" {
  description = "SSH Key for EC2 instance login"
  value       = "${aws_key_pair.ec2-speed-test-ssh-key.key_name}"
}

output "user_login" {
  description = "Login name for EC2 instance"
  value       = "ubuntu"
}

output "public_ip" {
  description = "EC2 instance public IP address"
  value       = "${aws_instance.ec2-speed-test-instance.public_ip}"
}
