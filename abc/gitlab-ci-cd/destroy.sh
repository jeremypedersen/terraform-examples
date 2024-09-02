#!/bin/bash

# Remove Ansible variable files
rm ansible/group_vars/*

# Remove PostgreSQL database account from the terraform state file
# (resolves an issue with resource deletion order during terraform destroy)
#terraform state rm alicloud_db_account.sonarqube_postgres_db_account

# Destroy the entire CI/CD environment
# GitLab, SonarQube, and all supporting resources will be deleted
# WARNGING: the OSS bucket holding GitLab's backups will also be deleted!
terraform destroy -auto-approve

# Remove SSH key files and secrets
rm *.pem
rm *.ak

# Remind user to clear entries from .ssh/known hosts
# (needs to be done before the next run of the setup script)
echo "Done! Note: before running setup.sh again, you may need to remove the entries for gitlab.yourdomain.com and sonar.yourdomain.com from your ~/.ssh/known_hosts file"
