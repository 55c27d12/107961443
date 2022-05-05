#!/bin/bash

# Remove generated key if exist
if [ -f "tf-test02-ec2-key.pem" ] ; then
       rm tf-test02-ec2-key.pem
fi       

# Configure AWS profile
aws configure --profile tech_test

# Terraform
terraform init
terraform plan -out terraform.out
terraform apply -auto-approve terraform.out

if [ -f "terraform.out" ] ; then
       rm "terraform.out"
fi

# change the permission of key
chmod 400 tf-test02-ec2-key.pem

