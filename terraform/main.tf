resource "aws_s3_bucket" "lambda" {
  bucket = "lambda-bucket-gkowalski"
}

resource "aws_s3_bucket" "bucket_origem" {
  bucket = "source-bucket-gkowalski"
}

resource "aws_s3_bucket" "bucket_destino" {
  bucket = "destionation-bucket-gkowalski"
}

# 2. PERMISSÕES (IAM ROLE) DA LAMBDA
resource "aws_iam_role" "lambda_role" {
  name = "role-lambda-s3-renamer"


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name = "lambda-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject", "s3:GetObject"]
      Resource = ["arn:aws:s3:::destionation-bucket-gkowalski/*", "arn:aws:s3:::source-bucket-gkowalski/*"]
      },
      {
        "Effect" : "Allow",
        "Action" : "logs:CreateLogGroup",
        "Resource" : "arn:aws:logs:us-east-1:321824335717:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : [
          "arn:aws:logs:us-east-1:321824335717:log-group:/aws/lambda/s3-file-renamer:*"
        ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

resource "aws_lambda_function" "lambda_function" {
  s3_bucket     = "lambda-bucket-gkowalski"
  s3_key        = "aws-lambda-java-starter-example-0.0.1.jar"
  function_name = "s3-file-renamer"
  role          = aws_iam_role.lambda_role.arn
  handler       = "org.example.Handler::handleRequest"
  runtime       = "java21"
  timeout       = 30

}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name # Nome da sua Lambda
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket_origem.arn # ARN do bucket de origem
}

resource "aws_s3_bucket_notification" "trigger_s3" {
  bucket = aws_s3_bucket.bucket_origem.id # ID do seu bucket de origem

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn

    events = [
      "s3:ObjectCreated:Put",
      "s3:ObjectCreated:Post"
    ]
  }

  depends_on = [aws_lambda_permission.allow_s3]
}