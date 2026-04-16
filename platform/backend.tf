terraform {
  backend "s3" {
    bucket = "toot-community-tfstate"
    key    = "platform/terraform.tfstate"
    region = "auto"

    endpoints = {
      s3 = "https://0ae89288096e9795bb1a5d327d89aec5.r2.cloudflarestorage.com"
    }

    use_lockfile                = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
