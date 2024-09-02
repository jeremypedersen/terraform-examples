#!/bin/bash
ssh-keygen -f owncloud-ssh-key -q -N ''
terraform apply --auto-approve
