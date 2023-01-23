variable "project" {
  type        = string
  description = "Project ID to create monitoring resources in"
}

variable "service_name" {
  type        = string
  description = "Display name of the custom service"
}

variable "telemetry_resource_name" {
  type        = string
  description = "The full name of the resource that defines this service"
  default     = " "
}

variable "default_user_labels" {
  type        = map(any)
  description = "User labels to be set for all alerts"
  default     = {}
}

variable "fallback_notification_channels" {
  type        = list(any)
  description = "List of display names for notification channels to be set for all alerts"
  default     = []
}

variable "notification_channel_ids" {
  type        = map(string)
  description = "Enables you to provide the the NCs 'display name' instead of 'id', { nc_display_name: nc_id  } or output from tf-module-gcp-notification-channels"
  default     = {}
}

variable "default_alert_documentation" {
  type        = string
  description = "Documentation to be set for all burn-rate alerts."
  default     = " "
}

variable "slos" {
  description = "Configuration for SLO"
  type        = any
}
