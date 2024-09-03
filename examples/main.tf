module "services-and-slos" {
  source  = "../"
  project = "my-gcp-project"
  services    = yamldecode(file("services-and-slos.yaml"))
  default_user_labels = {
    set_this_on_all_resources = true
  }

  # Notificaiton channels: Alt 1 - List of notification channels ids
  fallback_notification_channels = ["projects/my-gcp-project/notificationChannels/123456"]

  # Notificaiton channels: Alt 2 - Use friendly names for notification channels
  notification_channel_ids = {
    "important-alerts-channel" = "projects/my-gcp-project/notificationChannels/123456"
  }
  fallback_notification_channels = ["important-alerts-channel"]
}
