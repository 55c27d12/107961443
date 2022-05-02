#! /bin/bash

NAME=$1
if [ ${NAME} != "test02-lab" ] ; then 
	read -p "Please provide the ssh private key path: " KEY
else 
	KEY="ec2-access-key.pem"
fi

IP=$( aws ec2 describe-instances --filters "Name=tag:Name,Values=${NAME}" --profile tech_test --query "Reservations[*].Instances[*].PublicIpAddress" --output text)

if [ -z ${IP} ] ; then 
	echo "Host Not Found"
else
	if [ -f ${KEY} ] ; then
        	ssh -i ${KEY} ec2-user@${IP}
	else
        	echo "Cound not locate the ssh private key."
	fi
fi





