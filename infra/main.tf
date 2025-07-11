resource "aws_lambda_function" "myfunc" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "myfunc"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda.lambda_handler"
  runtime          = "python3.13"
}
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}
resource "aws_iam_policy" "lambda_exec_policy" {
  name        = "lambda_exec_policy"
  description = "IAM policy for Lambda execution role"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action : [
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ]
        Resource = "arn:aws:dynamodb:*:*:table/cloudresume"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_exec_policy_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_exec_policy.arn
}
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-fn/"
  output_path = "${path.module}/lambda_function.zip"
}
resource "aws_lambda_function_url" "myfunc_url" {
  function_name      = aws_lambda_function.myfunc.function_name
  authorization_type = "NONE"
  invoke_mode        = "BUFFERED"
  cors {
    allow_credentials = false
    allow_headers     = ["*"]
    allow_methods     = ["GET", "POST"]
    allow_origins     = ["https://sanyog.pscloud.in"]
    expose_headers    = ["ETag"]
    max_age           = 3600
  }
  depends_on = [aws_lambda_function.myfunc]
}
