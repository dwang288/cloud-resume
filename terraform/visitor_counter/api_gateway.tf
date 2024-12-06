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
