resource "aws_sns_topic" "broadcast" {
  name = "broadcast"

  tags = {
    Name = "broadcast"
  }
}

resource "aws_sqs_queue" "dead_letter_queue" {
  name                       = "queue-DLQ"
  message_retention_seconds  = 1 * 24 * 60 * 60
  visibility_timeout_seconds = 1

  tags = {
    Name = "queue-DLQ"
  }
}

resource "aws_sqs_queue" "queue" {
  name                       = "queue"
  message_retention_seconds  = 1 * 24 * 60 * 60
  visibility_timeout_seconds = 30

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 5
  })

  depends_on = [
    aws_sqs_queue.dead_letter_queue,
  ]

  tags = {
    Name = "queue"
  }
}

resource "aws_sqs_queue_policy" "queue" {
  queue_url = aws_sqs_queue.queue.id

  policy = data.aws_iam_policy_document.queue.json
}

resource "aws_sns_topic_subscription" "queue" {
  topic_arn = aws_sns_topic.broadcast.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.queue.arn

  filter_policy = jsonencode({
    eventType = [
      "bar",
      "echo",
      "example",
      "foo",
    ],
  })
}

data "aws_iam_policy_document" "queue" {
  statement {
    sid    = aws_sns_topic_subscription.queue.arn
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "SQS:SendMessage",
    ]

    resources = [
      aws_sqs_queue.queue.arn,
    ]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"

      values = [
        aws_sns_topic.broadcast.arn,
      ]
    }
  }
}
