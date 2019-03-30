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

/* Create an SNS topic and SQS queue for handling SES events.
 */
module "ses_queue" {
  source = "modules/ses_queue"
}

/* Configure SES to send and receive mail using the input domain.
 */
module "ses_domain" {
  source    = "modules/ses_domain"
  domain    = "${var.domain}"
  region    = "us-west-2"
  topic_arn = "${module.ses_queue.topic_arn}"
}

/* Create a lambda function to handle SES traffic.
 */
module "ses_handler" {
  source    = "modules/ses_handler"
  queue_arn = "${module.ses_queue.queue_arn}"
}
