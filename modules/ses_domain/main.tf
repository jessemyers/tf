data "aws_route53_zone" "ses_domain" {
  name = "${var.domain}"
}

/* Create an SES domain; this record initiates a verification process.
 */
resource "aws_ses_domain_identity" "ses_domain" {
  domain = "${var.domain}"
}

/* Create a DNS record to verify ownership of the domain.
 */
resource "aws_route53_record" "ses_domain_identity_verification_record" {
  zone_id = "${data.aws_route53_zone.ses_domain.id}"
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["${aws_ses_domain_identity.ses_domain.verification_token}"]
}

/* Initiate domain key (DKIM) process.
 */
resource "aws_ses_domain_dkim" "ses_domain" {
  domain = "${aws_ses_domain_identity.ses_domain.domain}"
}

/* Create DNS records to estabkkusg domain keys.
 */
resource "aws_route53_record" "ses_domain_key_verification_record" {
  count   = 3
  zone_id = "${data.aws_route53_zone.ses_domain.id}"
  name    = "${element(aws_ses_domain_dkim.ses_domain.dkim_tokens, count.index)}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.ses_domain.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

/* Create an MX record for inbound mail.
 */
resource "aws_route53_record" "ses_domain_mx_record" {
  zone_id = "${data.aws_route53_zone.ses_domain.id}"
  name    = "${var.domain}"
  type    = "MX"
  ttl     = "600"
  records = ["10 inbound-smtp.${var.region}.amazonaws.com"]
}

/* Send bounces to SNS.
 */
resource "aws_ses_identity_notification_topic" "bounce_notifications" {
  identity          = "${var.domain}"
  notification_type = "Bounce"
  topic_arn         = "${var.topic_arn}"
}

/* Send complaints to SNS.
 */
resource "aws_ses_identity_notification_topic" "complaint_notifications" {
  identity          = "${var.domain}"
  notification_type = "Complaint"
  topic_arn         = "${var.topic_arn}"
}

/* Send delivery confirmations to SNS.
 */
resource "aws_ses_identity_notification_topic" "delivery_notifications" {
  identity          = "${var.domain}"
  notification_type = "Delivery"
  topic_arn         = "${var.topic_arn}"
}

/* Create a rule set for inbound mail.
 */
resource "aws_ses_receipt_rule_set" "default" {
  rule_set_name = "default"
}

/* Create a rule to send inbound main to SNS.
 */
resource "aws_ses_receipt_rule" "default" {
  name          = "default"
  rule_set_name = "${aws_ses_receipt_rule_set.default.rule_set_name}"
  recipients    = ["${var.domain}"]
  enabled       = true
  scan_enabled  = true

  sns_action {
    topic_arn = "${var.topic_arn}"
    position  = 1
  }
}

/* Activate this rule set.
 */
resource "aws_ses_active_receipt_rule_set" "default" {
  rule_set_name = "${aws_ses_receipt_rule_set.default.rule_set_name}"
}
