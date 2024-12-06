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
