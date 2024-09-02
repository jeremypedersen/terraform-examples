#!/bin/bash

# Setup GitLab and SonarQube infrastructure
echo "Running terraform..."
terraform apply -auto-approve

# Create hosts file for Ansible
echo "Creating hosts file..."
echo "[gitlab]" > ansible/hosts
echo $(terraform output gitlab_url) >> ansible/hosts
echo "[sonar]" >> ansible/hosts
echo $(terraform output sonar_url) >> ansible/hosts

# Create Ansible variables file for gitlab variables
echo "Creating gitlab variables file for Ansible"
echo "---" > ansible/group_vars/gitlab

# Add comment lines to the file to explain how users should 
# set the DirectMail SMTP password, which must be done manually
echo "# Note: DirectMail password must be manually added on the line below. You should do this *after*" >> ansible/group_vars/gitlab
echo "# you run setup.sh (terraform) and *before* you run configure.sh (Ansible)." >> ansible/group_vars/gitlab
echo "# You must set the password manually from the DirectMail console. The password rules are fairly" >> ansible/group_vars/gitlab
echo "# complex:" >> ansible/group_vars/gitlab
echo "# - At least 20 characters long" >> ansible/group_vars/gitlab
echo "# - No longer than 20 characters" >> ansible/group_vars/gitlab
echo "# - Must ONLY contain numbers and letters" >> ansible/group_vars/gitlab
echo "# - Must contain at least two uppercase letters (and they cannot be the same letter)" >> ansible/group_vars/gitlab
echo "# - Must contain at least two lowercase letters (again, they must be distinct)" >> ansible/group_vars/gitlab
echo "# - Must contain at least two numbers (again, they must be distinct)" >> ansible/group_vars/gitlab
echo "# You may have to try several variations before you find a password that works. Once you've found" >> ansible/group_vars/gitlab
echo "# one, paste it in after the ":" on the line below. " >> ansible/group_vars/gitlab
echo "directmail_password: " >> ansible/group_vars/gitlab

# Set gitlab OSS bucket vars
echo "gitlab_hostname: $(terraform output gitlab_url)" >> ansible/group_vars/gitlab
echo "gitlab_bucket_name: $(terraform output gitlab_bucket_name)" >> ansible/group_vars/gitlab
echo "gitlab_bucket_endpoint: $(terraform output gitlab_bucket_endpoint)" >> ansible/group_vars/gitlab
echo "gitlab_bucket_ak: $(cat oss-fullaccess.ak | grep "AccessKeyId" | awk '{print $2}' | sed "s/\"//g")" >> ansible/group_vars/gitlab
echo "gitlab_bucket_ak_secret: $(cat oss-fullaccess.ak | grep "AccessKeySecret" | awk '{print $2}' | sed "s/,//g" | sed "s/\"//g")" >> ansible/group_vars/gitlab

# Set additional vars needed in gitlab.rb
echo "directmail_email: $(terraform output directmail_email)" >> ansible/group_vars/gitlab
echo "directmail_url: $(terraform output directmail_url)" >> ansible/group_vars/gitlab
echo "email_address: $(terraform output email_address)" >> ansible/group_vars/gitlab
echo "directmail_smtp_address: $(terraform output directmail_smtp_address)" >> ansible/group_vars/gitlab

# Create Ansible variable file for SonarQube variables
echo "Creating SonarQube variables file for Ansible"
echo "---" > ansible/group_vars/sonar

# Set SonarQube variables
echo "sonarqube_username: $(terraform output sonarqube_db_username)" >> ansible/group_vars/sonar
echo "sonarqube_password: $(terraform output sonarqube_db_password)" >> ansible/group_vars/sonar
echo "sonarqube_domain: $(terraform output sonarqube_domain)" >> ansible/group_vars/sonar
echo "sonarqube_db_connection_string: $(terraform output sonarqube_db_connection)" >> ansible/group_vars/sonar
echo "email_address: $(terraform output email_address)" >> ansible/group_vars/sonar

# Wait 10 seconds before exiting, to make sure users of this script
# don't immediately run ./configure.sh, which will fail if run too soon
echo "Waiting 10 seconds..."
sleep 10
echo "Done! You should now log into the Alibaba Cloud console, go to the DirectMail console, and verify your Email Domain."
echo "Once you've done that, there are 3 more steps to getting everything working:"
echo "1 - Create a new 'Sender Address' in the DirectMail console"
echo "2 - Set an SMTP password in the DirectMail console"
echo "3 - Copy-paste the password into ansible/group_vars/gitlab, on the 'directmail_password:' line"
echo "You can then run ./configure.sh to complete the configuration"
