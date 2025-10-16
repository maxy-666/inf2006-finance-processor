# aws_cloudfront_distribution.inf2006_distribution:
resource "aws_cloudfront_distribution" "inf2006_distribution" {
    aliases                         = []
    arn                             = "arn:aws:cloudfront::335360747232:distribution/EIB2DWMEGDT19"
    caller_reference                = "81a710ca-146b-4174-891e-d6121c39ff85"
    continuous_deployment_policy_id = null
    default_root_object             = null
    domain_name                     = "d3ms0gouo9fndn.cloudfront.net"
    enabled                         = true
    etag                            = "E3VMBS68SDGRQH"
    hosted_zone_id                  = "Z2FDTNDATAQYW2"
    http_version                    = "http2"
    id                              = "EIB2DWMEGDT19"
    in_progress_validation_batches  = 0
    is_ipv6_enabled                 = true
    last_modified_time              = "2025-10-14 15:31:36.101 +0000 UTC"
    price_class                     = "PriceClass_All"
    retain_on_delete                = false
    staging                         = false
    status                          = "Deployed"
    tags                            = {
        "Name" = "inf2006-frontend"
    }
    tags_all                        = {
        "Name" = "inf2006-frontend"
    }
    trusted_key_groups              = [
        {
            enabled = false
            items   = []
        },
    ]
    trusted_signers                 = [
        {
            enabled = false
            items   = []
        },
    ]
    wait_for_deployment             = true
    web_acl_id                      = "arn:aws:wafv2:us-east-1:335360747232:global/webacl/CreatedByCloudFront-d933304e/2e563300-8157-4c3c-a8e8-d3afe2745df0"

    default_cache_behavior {
        allowed_methods            = [
            "GET",
            "HEAD",
        ]
        cache_policy_id            = "658327ea-f89d-4fab-a63d-7e88639e58f6"
        cached_methods             = [
            "GET",
            "HEAD",
        ]
        compress                   = true
        default_ttl                = 0
        field_level_encryption_id  = null
        max_ttl                    = 0
        min_ttl                    = 0
        origin_request_policy_id   = null
        realtime_log_config_arn    = null
        response_headers_policy_id = null
        smooth_streaming           = false
        target_origin_id           = "http://inf2006-s3frontend.s3-website-us-east-1.amazonaws.com-mgqpxtsg9ev"
        trusted_key_groups         = []
        trusted_signers            = []
        viewer_protocol_policy     = "redirect-to-https"

        grpc_config {
            enabled = false
        }
    }

    origin {
        connection_attempts      = 3
        connection_timeout       = 10
        domain_name              = "inf2006-s3frontend.s3-website-us-east-1.amazonaws.com"  
        origin_access_control_id = null
        origin_id                = "http://inf2006-s3frontend.s3-website-us-east-1.amazonaws.com-mgqpxtsg9ev"
        origin_path              = null

        custom_origin_config {
            http_port                = 80
            https_port               = 443
            origin_keepalive_timeout = 5
            origin_protocol_policy   = "https-only"
            origin_read_timeout      = 30
            origin_ssl_protocols     = [
                "TLSv1.2",
            ]
        }
    }

    restrictions {
        geo_restriction {
            locations        = []
            restriction_type = "none"
        }
    }

    viewer_certificate {
        acm_certificate_arn            = null
        cloudfront_default_certificate = true
        iam_certificate_id             = null
        minimum_protocol_version       = "TLSv1"
        ssl_support_method             = null
    }
}