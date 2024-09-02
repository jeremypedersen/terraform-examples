# Use the remote state data source to output VPC information

output "vpc_info" {
    description = "VPC info pulled from remote state"
    value = "${data.terraform_remote_state.vpc.outputs.vpc_name}"
}