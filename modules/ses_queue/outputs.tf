output "queue_arn" {
  value = "${aws_sqs_queue.ses.arn}"
}

output "topic_arn" {
  value = "${aws_sns_topic.ses.arn}"
}
