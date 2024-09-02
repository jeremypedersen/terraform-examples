#
# Output the information required to test the
# environment created in main.tf
#

output "root_uid" {
  description = "UID of root account"
  value       = "${var.root_uid}"
}

output "other_uid" {
  description = "UID of other account"
  value       = "${var.other_uid}"
}
