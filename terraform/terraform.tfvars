# Default Terraform values (overridden by environment-specific values)
project     = "smartsphere"
environment = "dev"
aws_region  = "us-east-1"

# These variables need to be provided or referenced from env-specific files
route53_zone_id = "EXAMPLE-ZONE-ID"
certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/example"