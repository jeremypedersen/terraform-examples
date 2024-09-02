# Code to test accessing the remote state data source using terraform_remote_state

# Set up access to existing remote state (configure in ../main.tf)
data "terraform_remote_state" "vpc" {
    backend   = "oss"
    config    = {
        bucket = var.remote_state_bucket
        key    = var.remote_state_key
        region = var.remote_state_region

        assume_role = {
            role_arn = {role_arn = "${var.remote_role_arn}"}
        }
    }
    workspace = "default"
    outputs   = {}
}

