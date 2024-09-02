#!/bin/bash
openssl genrsa -out ec2-key-private.pem 2048
openssl rsa -in ec2-key-private.pem -outform PEM -pubout -out ec2-key-public.pem
ssh-keygen -i -m PKCS8 -f ec2-key-public.pem > ec2-ssh-key-public.key
