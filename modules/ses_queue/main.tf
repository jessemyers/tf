/* Create a topic for handling SES notifications.
 */
resource "aws_sns_topic" "ses" {
  name = "ses"
}

/* Create a dead letter queue for storing failed SES notifications.
 */
resource "aws_sqs_queue" "dlq" {
  name = "ses-dlq"
}

/* Create a queue for storing SES notifications.
 */
resource "aws_sqs_queue" "ses" {
  name = "ses"
  // docs suggest setting the max receive count to at least five
  redrive_policy = <<POLICY
{
  "deadLetterTargetArn": "${aws_sqs_queue.dlq.arn}",
  "maxReceiveCount": 5
}
POLICY
  // docs suggest setting the queue visibility timeout to six times the lambda timeout
  visibility_timeout_seconds = 30
}

/* Subscribe the queue to the topic.
 */
resource "aws_sns_topic_subscription" "ses" {
  endpoint  = "${aws_sqs_queue.ses.arn}"
  protocol  = "sqs"
  topic_arn = "${aws_sns_topic.ses.arn}"
}

/* Allow SNS to send messages to SQS.
 */
resource "aws_sqs_queue_policy" "ses" {
  policy    = "${data.aws_iam_policy_document.ses_to_sns_to_sqs.json}"
  queue_url = "${aws_sqs_queue.ses.id}"
}
