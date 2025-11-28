resource "aws_cloudfront_distribution" "inf2006_distribution" {
  enabled             = true
  retain_on_delete    = false # Set to true in production to keep the distribution when destroying the stack.
  price_class         = "PriceClass_All"
  
  origin {
    domain_name = aws_s3_bucket.inf2006-s3frontend.website_endpoint
    origin_id   = "S3-Website-inf2006-s3frontend" # A logical name for this origin.

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only" # S3 website endpoints use HTTP.
      origin_ssl_protocols     = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-Website-inf2006-s3frontend" # Must match the origin_id above.
    viewer_protocol_policy = "redirect-to-https"
    
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "inf2006-frontend"
  }
}
