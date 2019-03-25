provider "aws" {
  region = "us-west-2"
}

terraform {
  backend "s3" {
    bucket = "terraform.jessemyers.com"
    key    = "tf"
    region = "us-west-2"
  }
}

data "aws_route53_zone" "jessemyers" {
  name = "jessemyers.com."
}

resource "aws_ses_domain_identity" "contact" {
  domain = "contact.jessemyers.com"
}

resource "aws_route53_record" "contact_verification_record" {
  zone_id = "${data.aws_route53_zone.jessemyers.id}"
  name    = "_amazonses.example.com"
  type    = "TXT"
  ttl     = "600"
  records = ["${aws_ses_domain_identity.contact.verification_token}"]
}
