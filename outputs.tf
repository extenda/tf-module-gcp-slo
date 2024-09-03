output "services" {
  description = "Map of created services (both CUSTOM and CLOUD_RUN)"
  value = merge(
    { for k, v in google_monitoring_custom_service.custom_service : k => {
      id   = v.id
      name = v.display_name
      type = "CUSTOM"
    } },
    { for k, v in google_monitoring_service.cloud_run_service : k => {
      id   = v.id
      name = v.display_name
      type = "CLOUD_RUN"
    } }
  )
}

output "slos" {
  description = "Map of created SLOs"
  value = {
    for k, v in google_monitoring_slo.slo : k => {
      id           = v.id
      name         = v.display_name
      service_name = split("-", k)[0]
    }
  }
}

output "alerts" {
  description = "Map of created burn-rate alerts"
  value = {
    for k, v in google_monitoring_alert_policy.alert_policy : k => {
      id           = v.id
      name         = v.display_name
      service_name = split("-", k)[0]
    }
  }
}
