terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.52.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.9"
    }

    minio = {
      source  = "aminueza/minio"
      version = "~> 3.6.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "minio" {
  minio_server   = var.s3_server
  minio_user     = var.s3_access_key
  minio_password = var.s3_secret_key
  minio_region   = var.s3_region
  minio_ssl      = true
}
