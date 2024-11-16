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
  # TODO: should pass the path to the zipped file as a variable, or upload to s3
  filename      = "${path.module}/deployment.zip"
  function_name = "visitor_counter"
  role          = aws_iam_role.visitor_counter_lambda_role.arn
  handler       = "hello.handler"
  runtime       = "provided.al2023"
  architectures = ["arm64"]
  # Sanity check to make sure the policy is set up
  # TODO: Add another dependency on the existence of the published lambda code in the s3 bucket if possible
  depends_on = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

# File is zipped separately in CICD pipeline
resource "aws_lambda_function" "query_visitor_counter" {
  # TODO: should pass the path to the zipped file as a variable, or upload to s3
  filename      = "${path.module}/deployment.zip"
  function_name = "query_visitor_counter"
  role          = aws_iam_role.visitor_counter_lambda_role.arn
  handler       = "hello.handler"
  runtime       = "provided.al2023"
  architectures = ["arm64"]
  # Sanity check to make sure the policy is set up
  # TODO: Add another dependency on the existence of the published lambda code in the s3 bucket if possible
  depends_on = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

resource "aws_apigatewayv2_api" "visitor_counter" {
  name          = "visitor_counter-API"
  protocol_type = "HTTP"
  cors_configuration {
    # TODO: Replace with origin
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
  }
}

resource "aws_apigatewayv2_integration" "query_visitor_counter" {
  api_id                 = aws_apigatewayv2_api.visitor_counter.id
  integration_type       = "AWS_PROXY"
  integration_method     = "GET"
  integration_uri        = aws_lambda_function.query_visitor_counter.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_integration" "visitor_counter" {
  api_id                 = aws_apigatewayv2_api.visitor_counter.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.visitor_counter.invoke_arn
  payload_format_version = "2.0"
}


resource "aws_apigatewayv2_route" "query_visitor_counter_lambda" {
  api_id    = aws_apigatewayv2_api.visitor_counter.id
  route_key = "GET /visitor_counter"
  target    = "integrations/${aws_apigatewayv2_integration.query_visitor_counter.id}"
}

resource "aws_apigatewayv2_route" "visitor_counter_lambda" {
  api_id    = aws_apigatewayv2_api.visitor_counter.id
  route_key = "POST /visitor_counter"
  target    = "integrations/${aws_apigatewayv2_integration.visitor_counter.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.visitor_counter.id
  name        = "default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id = "AllowAPIGatewayInvoke"
  action       = "lambda:InvokeFunction"
  for_each = {
    visitor_counter_lambda       = aws_lambda_function.visitor_counter
    query_visitor_counter_lambda = aws_lambda_function.query_visitor_counter
  }
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_apigatewayv2_api.visitor_counter.execution_arn}/*/*/visitor_counter"
}


# TODO: Pull in the account name in the bucket name from a data source with the account id
# resource "aws_s3_bucket_website_configuration" "resume-site-prod-992382573336-us-east-2" {
#   bucket = aws_s3_bucket.example.bucket
# }
