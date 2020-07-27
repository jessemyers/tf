provider "aws" {
  region = "us-west-2"

  version = "~> 2.70"
}

resource "aws_s3_bucket" "terraform" {
  bucket = "terraform.jessemyers.com"
  acl    = "private"

  versioning {
    enabled = true
  }
}
