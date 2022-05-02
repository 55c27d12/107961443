terraform {
  backend "s3" {
    bucket         = "ixwongitdevopslabbucket"
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
  }
}
