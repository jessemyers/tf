/* Create a zip archive containing the lambda code.
 */
data "archive_file" "ses_handler" {
  type        = "zip"
  source_file = "${path.module}/ses_handler.py"
  output_path = "${path.module}/ses_handler.zip"
}

/* Create an IAM role for the lambda function.
 */
resource "aws_iam_role" "ses_handler" {
  name               = "ses_handler"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

/* Create an IAM policy for the lambda function.
 */
resource "aws_iam_policy" "ses_handler" {
  name   = "ses_handler"
  policy = "${data.aws_iam_policy_document.ses_handler.json}"
}

/* Attach the IAM policy to the IAM role.
 */
resource "aws_iam_role_policy_attachment" "ses_handler" {
  role       = "${aws_iam_role.ses_handler.name}"
  policy_arn = "${aws_iam_policy.ses_handler.arn}"
}

/* Create the lambda function.
 */
resource "aws_lambda_function" "ses_handler" {
  filename         = "${data.archive_file.ses_handler.output_path}"
  function_name    = "ses_handler"
  handler          = "ses_handler.ses_handler"
  // 128M is the default memory size
  memory_size      = 128
  runtime          = "python3.7"
  role             = "${aws_iam_role.ses_handler.arn}"
  source_code_hash = "${data.archive_file.ses_handler.output_base64sha256}"
  // docs suggest setting the queue visibility timeout (default 30s) to six times the lambda timeout
  timeout          = 5
}

/* Create an alias for the latest version of the lambda function.
 */
resource "aws_lambda_alias" "ses_handler" {
  name             = "default"
  description      = "Use latest version as default"
  function_name    = "${aws_lambda_function.ses_handler.function_name}"
  function_version = "$LATEST"
}

/* Subscribe the latest lambda function to the SNS queue.
 */
resource "aws_lambda_event_source_mapping" "ses_handler" {
  // processing one message at a time has the simplest error semantics at low volumes
  batch_size       = 1
  event_source_arn = "${var.queue_arn}"
  enabled          = true
  function_name    = "${aws_lambda_alias.ses_handler.arn}"
}

/* Create a dynamodb table.
 */
resource "aws_dynamodb_table" "ses_handler" {
  name           = "ses"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "email_address"

  attribute {
    name = "email_address"
    type = "S"
  }
}
