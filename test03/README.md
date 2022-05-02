# Test 03
This test is referring to question 3 - System design and Implementation
### Environment Setup
Please feel free to use my personal AWS credentials to test the script.

~/.aws/config
```
[profile tech_test]
region = ap-southeast-1
output = json
```
~/.aws/credentials
```
[tech_test]
aws_access_key_id = AKIA4RHWGGR7SFSGOQ4B
aws_secret_access_key = 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
```
Please ensure terraform installed on the machine.
https://learn.hashicorp.com/tutorials/terraform/install-cli


### Background
Please refer to design diagram.

[diagram](./design_diagram.png) 

There are some limitation on design this POC environment. I make use of AWS free tier to build the application using EC2 and docker mainly. 

### Limitation and Review
First, I took the video of https://www.youtube.com/watch?v=Z57566JBaZQ to implement the Node JS application. I convert it as a container image and implemented healthcheck endpoint. The image has been pushed to https://hub.docker.com/r/ixwongit/shorten-url. The following execution is only on terraform. Webapp container will be built via userdata to deploy the container.

Second, I am very sorry that I cannot avoid single point of failure on database layer of Mongodb. There is no enough resource to build a HA cluster of Mongodb so that I decide to build a mongodb container to ensure the consistency and stay in AWS. Also, I created a custom AMI image for the mongodb docker instance. It limits the terraform code must run on my personal AWS account environment. 

Third, I cannot use Route53 for domain names and internal DNS. The terraform will produce the corresponding API URL for reference.

For the review, this POC is quite simple in architecture perspective. In real environment, it is better to design using Route53 + AWS Gateway + Lambda / Webapp container on EKS/K8S on EC2 + DynamoDB. This provides the advanced HA, Scaling property, No single point of failure. 

### Usage
Ensure profile tech_test is configured
```
cd ./terraform/
terraform init
terraform plan
terraform apply -auto-approve
```

### Test Result
```
[ec2-user@ip-172-31-19-20 terraform]$ terraform apply -auto-approve
...
...
...
Outputs:

aws_alb_dns = "tf-webapp-alb-1523306254.ap-southeast-1.elb.amazonaws.com"
aws_alb_healthcheck_url = "http://tf-webapp-alb-1523306254.ap-southeast-1.elb.amazonaws.com/healthcheck"
aws_db_dns = "ip-172-31-54-226.ap-southeast-1.compute.internal"
[ec2-user@ip-172-31-19-20 terraform]$ 

[ec2-user@ip-172-31-19-20 ~]$ cat request.json 
{
  "url" : "https://yahoo.com/"
}
[ec2-user@ip-172-31-19-20 ~]$ curl -X POST -H "Content-type: application/json" -d @request.json http://tf-webapp-alb-1523306254.ap-southeast-1.elb.amazonaws.com/newurl
{"_id":"626fece8e8a80f00131f33b8","url":"https://yahoo.com/","shortUrl":"http://tf-webapp-alb-1523306254.ap-southeast-1.elb.amazonaws.com/2q7Hv5B7v","urlCode":"2q7Hv5B7v","date":"Mon May 02 2022 14:38:32 GMT+0000 (Coordinated Universal Time)","__v":0}[ec2-user@ip-172-31-19-20 ~]$ 
[ec2-user@ip-172-31-19-20 ~]$ curl http://tf-webapp-alb-1523306254.ap-southeast-1.elb.amazonaws.com/2q7Hv5B7v
Found. Redirecting to https://yahoo.com/[ec2-user@ip-172-31-19-20 ~]$ 
[ec2-user@ip-172-31-19-20 ~]$ 
```

### Environment clean up
```
[ec2-user@ip-172-31-19-20 terraform]$ terraform destroy
```

### Contributor 

Ivan Wong (2022-May-2)