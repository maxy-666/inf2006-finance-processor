# Defines the CloudFront distribution to serve the website content globally.
resource "aws_cloudfront_distribution" "inf2006_distribution" {
  enabled             = true
  retain_on_delete    = false # Set to true in production if you want to keep the distribution when destroying the stack.
  price_class         = "PriceClass_All"
  
  # The origin is the source of the files - in this case, our S3 website.
  origin {
    # We dynamically get the website endpoint from the S3 bucket resource.
    domain_name = aws_s3_bucket.inf2006-s3frontend.website_endpoint
    origin_id   = "S3-Website-inf2006-s3frontend" # A logical name for this origin.

    # This tells CloudFront that the origin is a custom web server (not just a plain S3 bucket).
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only" # S3 website endpoints use HTTP.
      origin_ssl_protocols     = ["TLSv1.2"]
    }
  }

  # This defines how CloudFront handles requests from users.
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-Website-inf2006-s3frontend" # Must match the origin_id above.
    viewer_protocol_policy = "redirect-to-https"
    
    # Use a standard caching policy managed by AWS for optimal performance.
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # CachingOptimized
  }

  # Configures the SSL/TLS certificate.
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Defines any geographic restrictions.
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "inf2006-frontend"
  }
}
