#
# Cross Account Logging
# 
# Allows log collection from one or more Alibaba Cloud
# accounts into a single master account.
#
# 1 - Creates shared services and application accounts
# 2 - Enables and configures cross-account logging
# 3 - Creates RAM accounts and associated Roles + Policies
#
# Author: Jeremy Pedersen
# Created 2020-02-05
# Updated: 2020-02-05

###
# Configure providers for our two Alibaba Cloud accounts
###

###
# Configure root account and associated RAM accounts
###

# Root account (logging, bill payment)
provider "alicloud" {
  alias      = "root"
  access_key = "${var.root_ak}"
  secret_key = "${var.root_secret}"
  region     = "${var.region}"
  version    = "~> 1.63"
}

provider "alicloud" {
  alias      = "other"
  access_key = "${var.other_ak}"
  secret_key = "${var.other_secret}"
  region     = "${var.region}"
  version    = "~> 1.63"
}

### 
# Log Services Configuration
###

# Create a local variable to hold the account UIDs
# of all the accounts we'd like to collect logs from
# under the master account
locals {
  account_ids = ["${var.other_uid}"]
}

# ActionTrail Configuration (root)
module "root_actiontrail" {
  source = "./root_actiontrail"
  providers = {
    alicloud = "alicloud.root"
  }
  # WARNING: Don't forget to add IDs for each new account you create in your organization
  account_ids = "${local.account_ids}"

}

# ActionTrail Configuration (other account or accounts)
module "sub_actiontrail" {
  source = "./other_actiontrail"
  providers = {
    alicloud = "alicloud.other"
  }
  root_uid = "${var.root_uid}"
}
