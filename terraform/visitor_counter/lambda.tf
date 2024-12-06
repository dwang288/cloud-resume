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

  name = "AWSLambdaBasicExecutionRole"
  path = "/service-role/"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:us-east-2:${var.account_id}:*",
          "Effect" : "Allow"
        }
      ]
    }
  )
}

# TODO: Pull those randomly generated names into a data source/variable
resource "aws_iam_policy" "lambda_microservice_execution_policy" {

  name = "AWSLambdaMicroserviceExecutionRole"
  path = "/service-role/"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:DeleteItem",
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:Scan",
            "dynamodb:UpdateItem"
          ],
          "Resource" : "arn:aws:dynamodb:us-east-2:${var.account_id}:table/*"
        }
      ]
    }
  )
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
