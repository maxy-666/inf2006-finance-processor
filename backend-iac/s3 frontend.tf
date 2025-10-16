# backend-iac/s3.tf

resource "aws_s3_bucket" "inf2006-s3frontend" {
    acceleration_status         = null
    arn                         = "arn:aws:s3:::inf2006-s3frontend"
    bucket                      = "inf2006-s3frontend"
    bucket_domain_name          = "inf2006-s3frontend.s3.amazonaws.com"
    bucket_prefix               = null
    bucket_regional_domain_name = "inf2006-s3frontend.s3.us-east-1.amazonaws.com"
    hosted_zone_id              = "Z3AQBSTGFYJSTF"
    id                          = "inf2006-s3frontend"
    object_lock_enabled         = false
    policy                      = jsonencode(
        {
            Statement = [
                {
                    Action    = "s3:GetObject"
                    Effect    = "Allow"
                    Principal = "*"
                    Resource  = "arn:aws:s3:::inf2006-s3frontend/*"
                    Sid       = "PublicReadGetObject"
                },
            ]
            Version   = "2012-10-17"
        }
    )
    region                      = "us-east-1"
    request_payer               = "BucketOwner"
    tags                        = {}
    tags_all                    = {}
    website_domain              = "s3-website-us-east-1.amazonaws.com"
    website_endpoint            = "inf2006-s3frontend.s3-website-us-east-1.amazonaws.com"   

    grant {
        id          = "5862a41519974ff95b5bf4f641b5398fb7a3588e9755bc84760351b820abee5d"    
        permissions = [
            "FULL_CONTROL",
        ]
        type        = "CanonicalUser"
        uri         = null
    }

    server_side_encryption_configuration {
        rule {
            bucket_key_enabled = true

            apply_server_side_encryption_by_default {
                kms_master_key_id = null
                sse_algorithm     = "AES256"
            }
        }
    }

    versioning {
        enabled    = false
        mfa_delete = false
    }

    website {
        error_document           = "error.html"
        index_document           = "index.html"
        redirect_all_requests_to = null
        routing_rules            = null
    }
}