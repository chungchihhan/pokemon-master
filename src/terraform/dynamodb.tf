resource "aws_dynamodb_table" "pokemon_table" {
  name         = var.dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "ID"
  range_key = "timestamp"

  attribute {
    name = "ID"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = {
    Name = "Pokemon Master"
  }
}