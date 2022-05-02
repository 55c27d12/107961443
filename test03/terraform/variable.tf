variable "aws_region" {
  default = "ap-southeast-1"
}

variable "aws_profile" {
  default = "tech_test"
}

variable "ami_id" {
  default = "ami-0cc8dc7a69cd8b547"
}

variable "vpc_id" {
  default = "vpc-0a44976c"
}

variable "vpc_subnet_id" {
  default = ["subnet-2e2d5f77", "subnet-54ee591c", "subnet-50991e36"]
}

variable "webapp_key" {
  default = "webapp-key"
}

variable "db_key" {
  default = "mongodb-key"
}

variable "db_ami_id" {
  default = "ami-0568a64df553d5f9a"
}
