data "aws_cloudfront_cache_policy" "example" {
  name = "Managed-CachingOptimized"
}

module "cdn" {
  source = "terraform-aws-modules/cloudfront/aws"

  comment             = "CloudFront for Pokemon Master S3 static website"
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  retain_on_delete    = false
  wait_for_deployment = false

  create_origin_access_identity = false

  origin = {
    s3_static_web = {
        domain_name = "${module.s3_bucket.s3_bucket_website_endpoint}"
        custom_origin_config = {
            http_port              = 80
            https_port             = 443
            origin_protocol_policy = "http-only"
            origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }
    }
  }
  


  default_cache_behavior = {
    target_origin_id           = "s3_static_web"
    viewer_protocol_policy     = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    compress        = true
    query_string    = false
  }

}