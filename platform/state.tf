terraform {
  backend "s3" {
    use_lockfile                = true
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    use_path_style              = true
    bucket                      = var.state_bucket_name
    key                         = "environments/${var.environment}/terraform.tfstate"
    region                      = "eu-central-1"

    endpoints = {
      "s3" = "https://fsn1.your-objectstorage.com"
    }
  }
}
