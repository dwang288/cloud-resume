locals {
  region = "us-east-2"
}

# DynamoDB table for visitor counter

resource "aws_dynamodb_table" "visitor_counter" {
  name      = "visitor_counter"
  hash_key  = "PK"
  range_key = "SK"

  attribute {
    name = "PK"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }
}

resource "aws_iam_role" "visitor_counter_lambda_role" {
  name               = "Lambda-Prod-Counter-FullAccess"
  path               = "/service-role/"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow"
   }
 ]
}
EOF
}

# TODO: Pull those randomly generated names into a data source/variable

resource "aws_iam_policy" "lambda_basic_execution_policy" {

  name   = "AWSLambdaBasicExecutionRole-198e9a51-87c3-4b30-a956-bfbe33e20e52"
  path   = "/service-role/"
  policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": [
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:logs:us-east-2:992382573336:*",
     "Effect": "Allow"
   }
 ]
}
EOF
}

# TODO: Pull those randomly generated names into a data source/variable
resource "aws_iam_policy" "lambda_microservice_execution_policy" {

  name   = "AWSLambdaMicroserviceExecutionRole-5ceef68d-bf1b-429c-a1e0-3505166debaa"
  path   = "/service-role/"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:Scan",
                "dynamodb:UpdateItem"
            ],
            "Resource": "arn:aws:dynamodb:us-east-2:992382573336:table/*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  for_each = {
    basic        = aws_iam_policy.lambda_basic_execution_policy.arn
    microservice = aws_iam_policy.lambda_microservice_execution_policy.arn
  }
  role       = aws_iam_role.visitor_counter_lambda_role.name
  policy_arn = each.value
}

# File is zipped separately in CICD pipeline
resource "aws_lambda_function" "visitor_counter" {
  # TODO: should pass the path to the zipped file as a variable
  filename      = "${path.module}/deployment.zip"
  function_name = "visitor_counter"
  role          = aws_iam_role.visitor_counter_lambda_role.arn
  handler       = "hello.handler"
  runtime       = "provided.al2023"
  architectures = ["arm64"]
  # Sanity check to make sure the policy is set up
  depends_on = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

# TODO: Pull in the account name in the bucket name from a data source with the account id
# resource "aws_s3_bucket_website_configuration" "resume-site-prod-992382573336-us-east-2" {
#   bucket = aws_s3_bucket.example.bucket
# }
