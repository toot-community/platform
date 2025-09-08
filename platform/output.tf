output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}

output "object_storage_access_credentials" {
  value = {
    for k, v in upcloud_managed_object_storage_user_access_key.this :
    k => {
      username          = upcloud_managed_object_storage_user.this[k].username
      access_key_id     = v.access_key_id
      secret_access_key = v.secret_access_key,
      bucket            = upcloud_managed_object_storage_bucket.this[k].name
      endpoint          = upcloud_managed_object_storage.this.endpoint
    }
  }
  sensitive = true
}
