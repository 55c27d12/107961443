data "aws_vpc" "main" {
  id = var.vpc_id
}

data "template_file" "tf_webapp_userdata" {
  template = file("./userdata/webapp_userdata.tpl")

  vars = {
    terraform_webapp_alb_url = aws_lb.tf-webapp-alb.dns_name
    terraform_db_host        = aws_instance.tf-mongodb.private_dns
  }
}
