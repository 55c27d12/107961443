#! /bin/bash

NAME=$1
KEY="tf-test02-ec2-key.pem"

IP=$( aws ec2 describe-instances --filters "Name=tag:Name,Values=${NAME}" --profile tech_test --query "Reservations[*].Instances[*].PublicIpAddress" --output text)

if [ -z ${IP} ] ; then 
	echo "Host Not Found"
else
	if [ -f ${KEY} ] ; then
        	ssh -i ${KEY} ec2-user@${IP}
	else
        	echo "Cound not locate the ssh private key. Please replace ssh key in Bash."
	fi
fi





