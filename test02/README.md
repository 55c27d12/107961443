# Test 02
This test is referring to question 2 - AWS​ API​ programming

### Background
It is writen by bash script. The script execute AWS CLI to query the EC2 public ip address and return to the execution of ssh. 

### Environment Setup
Please feel free to use my personal AWS access key to test the script or use your own access key.
Please ensure aws-cli has been installed.

The AWS user should have the below policy for ./setup_env.sh
- AmazonEC2FullAccess
- AmazonVPCFullAccess

If you have your own environment, please ensure your user has below policy to read EC2 information. ./aws_query_ec2.sh contain a variable of ssh key name - 
- AmazonEC2ReadOnlyAccess

~/.aws/config   (There is a setting for profile name tech_tets)
```
[profile tech_test]
region = ap-southeast-1
output = json
```
<mark>Important</mark>

Please ensure 10.1.0.0/16 is not used for VPC CIDR.

### [setup_env.sh](setup_env.sh)
This script is to setup (1) AWS profile and (2) terraform script to create a EC2 named "" and generate the ssh key named ""
```
chmod +x setup_env.sh
./setup_env.sh
```
Example. Please input the access key and secret key. We use ap-southeast-1 region for the testing.
```
[ec2-user@ip-172-31-19-20 test02]$ ./setup_env.sh 
AWS Access Key ID [****************22OH]: 
AWS Secret Access Key [****************a8ln]: 
Default region name [ap-southeast-1]: 
Default output format [json]: 
...
...
aws_instance.tf-test02-ec2: Still creating... [10s elapsed]
aws_instance.tf-test02-ec2: Still creating... [20s elapsed]
aws_instance.tf-test02-ec2: Still creating... [30s elapsed]
aws_instance.tf-test02-ec2: Still creating... [40s elapsed]
aws_instance.tf-test02-ec2: Creation complete after 42s [id=i-00577c810e9e43fee]

Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs:

ec2-tags = tomap({
  "Name" = "tf-test02-ec2"
})
[ec2-user@ip-172-31-19-20 test02]$ 
```
"tf-test02-ec2" is the testing EC2 instance name


### Usage of [aws_query_ec2.sh](aws_query_ec2.sh)
```
chmod +x aws_query_ec2.sh
./aws_query_ec2.sh {INSTANCE_NAME}
```

### Testing result
```
[ec2-user@ip-172-31-19-20 test02]$ chmod +x aws_query_ec2.sh 
[ec2-user@ip-172-31-19-20 test02]$ ./aws_query_ec2.sh tf-test02-ec2
The authenticity of host '54.179.30.240 (54.179.30.240)' can't be established.
ECDSA key fingerprint is SHA256:UjYJRNfPYeHqmE6YfcpwHjwjhsyr8S2kwbfBSrSQA4Y.
ECDSA key fingerprint is MD5:aa:5c:88:01:dc:82:a7:93:e5:d4:04:3f:c8:bd:ca:b7.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '54.179.30.240' (ECDSA) to the list of known hosts.

       __|  __|_  )
       _|  (     /   Amazon Linux 2 AMI
      ___|\___|___|

https://aws.amazon.com/amazon-linux-2/
12 package(s) needed for security, out of 28 available
Run "sudo yum update" to apply all updates.
[ec2-user@ip-10-1-1-208 ~]$ exit
logout
Connection to 54.179.30.240 closed.
[ec2-user@ip-172-31-19-20 test02]$ ./aws_query_ec2.sh unknown
Host Not Found
[ec2-user@ip-172-31-19-20 test02]$ 
```

### Environment cleanup
```
[ec2-user@ip-172-31-19-20 test02]$ chmod +x cleanup.sh 
[ec2-user@ip-172-31-19-20 test02]$ ./cleanup.sh 
```

### Contributor 

Ivan Wong (2022-May-5)