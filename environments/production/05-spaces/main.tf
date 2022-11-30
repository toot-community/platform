module "spaces" {
  source = "../../../modules/spaces"

  spaces_name   = "files-toot-community"
  region        = "ams3"
  cdn_hostname  = "files.toot.community"
  cors_hostname = "toot.community"
}

module "spaces-backups" {
  source = "../../../modules/spaces"

  spaces_name   = "backup-toot-community"
  region        = "ams3"
}
