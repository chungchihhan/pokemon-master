resource "random_string" "this" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

# In your current folder's main.tf or a new file
data "terraform_remote_state" "api" {
  backend = "local"
  
  config = {
    path = "../../src/terraform/terraform.tfstate"  # Adjust this path to point to your API Gateway state file
  }
}

# locals {
#   source_path = "${path.module}/.."
#   path_include                                    = ["**"]
#   path_exclude                                    = ["**/__pycache__/**"]
#   files_include                                   = setunion([for f in local.path_include : fileset(local.source_path, f)]...)
#   files_exclude                                   = setunion([for f in local.path_exclude : fileset(local.source_path, f)]...)
#   files                                           = sort(setsubtract(local.files_include, local.files_exclude))
#   dir_sha                                         = sha1(join("", [for f in local.files : filesha1("${local.source_path}/${f}")]))
# }


locals {
  bucket_name = "${var.bucket_name}-${random_string.this.result}"
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:PutObject", "s3:GetObject"]

    resources = [
      "arn:aws:s3:::${local.bucket_name}/*",
    ]
  }
}


module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = local.bucket_name

  # Enable static website hosting
  website = {
    index_document = "index.html"
    error_document = "error.html"
  }

  # Configure CORS
  cors_rule = [
    {
      allowed_methods = ["GET", "HEAD"]
      allowed_origins = ["*"]
      allowed_headers = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]

  # Disable block public policies
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  attach_policy = true
  policy = data.aws_iam_policy_document.bucket_policy.json
  force_destroy = true

  tags = {
    Owner = "YourName"
    Environment = "Dev"
  }
}

# Read the raw HTML template file
data "local_file" "index_html_template" {
  filename = "./index.html"
}

resource "aws_s3_object" "index_html" {
  bucket        = module.s3_bucket.s3_bucket_id
  key           = "index.html"
  content       = replace(data.local_file.index_html_template.content, "INVOKE_URL_PLACEHOLDER", data.terraform_remote_state.api.outputs.invoke_url)
  content_type  = "text/html"
}


resource "aws_s3_object" "error_html" {
  bucket = module.s3_bucket.s3_bucket_id
  key    = "error.html"
  source = "./error.html"
  etag   = filemd5("./error.html")
  content_type = "text/html"
}

resource "aws_s3_object" "styles_css" {
  bucket = module.s3_bucket.s3_bucket_id
  key    = "styles.css"
  source = "./styles.css"
  etag   = filemd5("./styles.css") # Ensures the object is updated only when the file changes
  content_type = "text/css"
}

resource "aws_s3_object" "pokeball_png" {
  bucket = module.s3_bucket.s3_bucket_id
  key    = "pokeball.png"
  source = "./pokeball.png"
  etag   = filemd5("./pokeball.png") # Ensures the object is updated only when the file changes
}

resource "aws_s3_object" "red_backpack_png" {
  bucket = module.s3_bucket.s3_bucket_id
  key    = "red_backpack.png"
  source = "./red_backpack.png"
  etag   = filemd5("./red_backpack.png") # Ensures the object is updated only when the file changes
}