resource "aws_dynamodb_table" "pokemon_table" {
  name         = var.dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "ID"

  attribute {
    name = "ID"
    type = "S"
  }

  tags = {
    Name = "Pokemon Master"
  }
}