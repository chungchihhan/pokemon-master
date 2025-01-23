output "s3_static_website_endpoint" {
  value = module.s3_bucket.s3_bucket_website_endpoint
}

output "cloudfront_domain_name" {
  value = module.cdn.cloudfront_distribution_domain_name
}