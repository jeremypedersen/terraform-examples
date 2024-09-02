#
# Output the information required to test the
# environment created in main.tf
#
# - Username for bastion host (same for all instances)
# - SSH key name for login (to the management instance)
# - Password for login (to the dev, staging, and prod instances)
# - Public IP address for bastion host
#
# We also output the private IP addresses for each instance:
#
# - Private IP for development instance
# - Private IP for staging instance
# - Private IP for production instance
# - Private IP for management instance
#
# Testing the environment:
# 
# - Log in to the bastion host. From there, use SSH to log into
# any of (dev, staging, prod) and use ping to confirm security group
# rules are restricting traffic flow like so:
# 
# development -> staging -> production

output "username" {
  description = "Username for instance login (all instances)"
  value       = "root"
}

output "ssh_key" {
  description = "SSH key for instance login (management instance ONLY)"
  value       = "${var.ssh_key_name}.pem"
}

output "password" {
  description = "Password for instance login (development, staging, and production instances)"
  value = "${var.password}"
}

output "bastion_ip" {
  description = "Public IP address of our new bastion host"
  value       = "${alicloud_instance.tf_example_management.public_ip}"
}

output "dev_private_ip" {
  description = "Private IP of development instance"
  value       = "${alicloud_instance.tf_example_dev.private_ip}"
}

output "staging_private_ip" {
  description = "Private IP of staging instance"
  value       = "${alicloud_instance.tf_example_staging.private_ip}"
}

output "prod_private_ip" {
  description = "Private IP of production instance"
  value       = "${alicloud_instance.tf_example_production.private_ip}"
}

output "bastion_private_ip" {
  description = "Private IP of management instance"
  value       = "${alicloud_instance.tf_example_management.private_ip}"
}
