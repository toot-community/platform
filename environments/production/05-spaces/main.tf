module "spaces" {
  source = "../../../modules/spaces"

  spaces_name = "static-toot-community"
  region      = "ams3"
}

module "spaces-db-backups" {
  source = "../../../modules/spaces"

  spaces_name = "db-backup-toot-community"
  region      = "ams3"
}

module "spaces-loki" {
  source = "../../../modules/spaces"

  spaces_name = "loki-toot-community"
  region      = "ams3"
}


module "spaces-velero" {
  source = "../../../modules/spaces"

  spaces_name = "velero-toot-community"
  region      = "ams3"
}
