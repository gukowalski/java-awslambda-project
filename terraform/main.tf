resource "aws_s3_bucket" "lambda" {
  bucket = "lambda-bucket-gkowalski"
}

# 1. BUCKETS S3
resource "aws_s3_bucket" "bucket_origem" {
  bucket = "source-bucket-gkowalski"
}

resource "aws_s3_bucket" "bucket_destino" {
  bucket = "destionation-bucket-gkowalski"
}

