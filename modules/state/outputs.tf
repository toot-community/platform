output "state-bucket-name" {
  value = digitalocean_spaces_bucket.state.name
}

output "state-bucket-region" {
  value = digitalocean_spaces_bucket.state.region
}
