# Test 02
This test is referring to question 2 - AWS​ API​ programming
### Environment Setup
Please feel free to use my personal AWS credentials to test the script.
Please ensure aws-cli has been installed.

~/.aws/config
```
[profile tech_test]
region = ap-southeast-1
output = json
```
~/.aws/credentials
```
[tech_test]
aws_access_key_id = ACCESS_KEY
aws_secret_access_key = SECRET_KEY
```
### Usage
```
# It is real AWS account and I have set ssh key for the testing machine
chmod 400 ec2-access-key.pem
chmod +x aws_query_ec2.sh
# test02-lab has been reserved for question 2 testing
./aws_query_ec2.sh test02-lab
```

### Background
It is writen by bash script. The script execute AWS CLI to query the EC2 public ip address and return to the second execition of ssh. I have implemented ssh key related logic in the bash script to ensure it can connect without access issue.

### Testing result
```
[ec2-user@ip-172-31-19-20 test02]$ chmod 400 ec2-access-key.pem 
[ec2-user@ip-172-31-19-20 test02]$ ./aws_query_ec2.sh test02-lab

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/
12 package(s) needed for security, out of 28 available
Run "sudo yum update" to apply all updates.
[ec2-user@ip-172-31-46-217 ~]$ exit
logout
Connection to 18.141.233.130 closed.
[ec2-user@ip-172-31-19-20 test02]$ ./aws_query_ec2.sh unknown
Please provide the ssh private key path: ec2-access-key.pem
Host Not Found
[ec2-user@ip-172-31-19-20 test02]$ 
```

### Contributor 

Ivan Wong (2022-May-2)