#!/bin/bash

# Remove terraform cache
terraform destroy -auto-approve
rm -rf terraform.tfstate*
rm -rf .terraform*
rm -f tf-test02-ec2-key.pem
