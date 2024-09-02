#
# Output the information required to test the
# environment created in main.tf
#
# - Username for instance
# - Public IP address for instance
# - SSH key name (for instance login)
#
output "username" {
  description = "Username for instance login (all instances)"
  value       = "root"
}

output "public_ip" {
  description = "Instance public IP address"
  value       = "${alicloud_instance.speed-test-ecs.public_ip}"
}

output "ssh_key_file" {
  description = "Name of SSH key for instance login"
  value = "${var.ssh_key_name}.pem"
}