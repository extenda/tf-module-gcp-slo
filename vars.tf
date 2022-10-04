variable monitoring_project_id {
  type        = string
  description = "Project ID to create monitoring resources in"
  default     = "hiiretail-monitoring-prod-6500"
}

variable service_name {
  type        = string
  description = "Display name of the custom service"
}

variable telemetry_resource_name {
  type        = string
  description = "The full name of the resource that defines this service"
  default     = null
}

variable notification_channels {
  type        = list(any)
  description = "List of notificaton channel IDs"
  default     = []
}

variable slos {
  description = "Configuration for SLO"
  type        = any
}

variable documentation {
  type        = string
  description = "Documentation that is included with notifications and incidents related to the burn-rate alerts."
  default     = " "
}

variable user_labels {
  type        = map(any)
  description = "Project ID to create monitoring resources in"
  default     = {}
}
