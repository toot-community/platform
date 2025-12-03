terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.57.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.9"
    }

    upcloud = {
      source  = "UpCloudLtd/upcloud"
      version = "~> 5.31.0"
    }

    objsto = {
      source  = "UpCloudLtd/objsto"
      version = "~> 0.2.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "objsto" {
  endpoint   = "https://${tolist(upcloud_managed_object_storage.this.endpoint)[0].domain_name}"
  region     = "auto"
  access_key = upcloud_managed_object_storage_user_access_key.terraform.access_key_id
  secret_key = upcloud_managed_object_storage_user_access_key.terraform.secret_access_key
}
