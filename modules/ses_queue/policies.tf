data "aws_iam_policy_document" "ses_to_sns_to_sqs" {
  policy_id = "SESToSNSToSQS"

  statement {
    actions = [
      "sqs:SendMessage",
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        "${aws_sns_topic.ses.arn}",
      ]
    }

    effect = "Allow"

    principals {
      type = "AWS"

      identifiers = [
        "*",
      ]
    }

    resources = [
      "${aws_sqs_queue.ses.arn}",
    ]

    sid = "AllowSESToSNSToWriteToSQS"
  }
}
