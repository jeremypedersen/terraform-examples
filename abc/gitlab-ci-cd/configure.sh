#!/bin/bash

# Save SSH key name to an environment variable
export SSH_KEY=$(terraform output ssh_key_name)

# Restrict SSH key permissions
chmod 600 $SSH_KEY

# Run Ansible playbook to install and configure GitLab and SonarQube
echo "Running Ansible playbooks..."
cd ansible
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i hosts --key-file ../$SSH_KEY site.yml
