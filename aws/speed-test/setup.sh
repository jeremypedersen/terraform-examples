#!/bin/bash
ssh-keygen -f ec2-speed-test-ssh-key -q -N ''
terraform apply --auto-approve
