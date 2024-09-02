#!/bin/bash
ssh-keygen -f dev-staging-test-ssh-key -q -N ''
terraform apply --auto-approve
