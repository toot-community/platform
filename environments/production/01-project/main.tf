module "project" {
  source = "../../../modules/project"

  project_name        = "toot.community"
  project_description = "Project containing the toot.community platform"
  project_environment = "Production"
}
