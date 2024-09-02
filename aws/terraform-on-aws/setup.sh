#!/bin/bash
ssh-keygen -f ec2-example-ssh-key -q -N ''
terraform apply --auto-approve
