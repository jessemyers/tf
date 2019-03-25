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

resource "aws_ses_domain_identity" "jessemyers" {
  domain = "jessemyers.com"
}

resource "aws_route53_record" "domain_identity_verification_record" {
  zone_id = "${data.aws_route53_zone.jessemyers.id}"
  name    = "_amazonses.jessemyers.com"
  type    = "TXT"
  ttl     = "600"
  records = ["${aws_ses_domain_identity.jessemyers.verification_token}"]
}

resource "aws_ses_domain_dkim" "jessemyers" {
  domain = "${aws_ses_domain_identity.jessemyers.domain}"
}

resource "aws_route53_record" "domain_key_verification_record" {
  count   = 3
  zone_id = "${data.aws_route53_zone.jessemyers.id}"
  name    = "${element(aws_ses_domain_dkim.jessemyers.dkim_tokens, count.index)}._domainkey.jessemyers.com"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.jessemyers.dkim_tokens, count.index)}.dkim.amazonses.com"]
}
