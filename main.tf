locals {
  services_with_type = [
    for service in var.services : {
      service = merge(service.service, {
        type        = try(service.service.type, "CLOUD_RUN")
        user_labels = try(service.service.user_labels, {})
      })
      slos = [
        for slo in service.slos : merge(slo, {
          alert = try(slo.alert, {})
          // Replace non-alphanumeric with dashes
          formatted_name = lower(
            replace(
              replace(
                replace(
                  slo.display_name,
                  "/[^a-zA-Z0-9]+/", "-"
                ),
                "/^-+|-+$/", ""
              ),
              "--", "-"
            )
          )
          user_labels = try(service.service.user_labels, {})
        })
      ]
    }
  ]
  default_alert = {
    prio              = "P2"
    condition_name    = "High consumption of error budget"
    lookback_duration = "3600s" # 1h
    duration          = "0s"
    threshold_value   = 10
    description       = "Service is consuming too much error budget. It may run out soon if performance doesn't improve"
  }
  custom_services                = { for service in local.services_with_type : service.service.name => service if service.service.type == "CUSTOM" }
  cloud_run_services             = { for service in local.services_with_type : service.service.name => service if service.service.type == "CLOUD_RUN" }
  fallback_notification_channels = [for nc in var.fallback_notification_channels : try(var.notification_channel_ids[nc], nc)]
}

resource "google_monitoring_custom_service" "custom_service" {
  for_each = local.custom_services

  project      = var.project
  service_id   = each.value.service.name
  display_name = each.value.service.name
  user_labels  = merge(var.default_user_labels, try(each.value.user_labels, {}))

  telemetry {
    resource_name = try(each.value.service.telemetry_resource_name, " ")
  }
}

resource "google_monitoring_service" "cloud_run_service" {
  for_each = local.cloud_run_services

  project      = var.project
  service_id   = each.value.service.name
  display_name = each.value.service.name
  user_labels  = merge(var.default_user_labels, each.value.service.user_labels)

  basic_service {
    service_type = "CLOUD_RUN"
    service_labels = {
      service_name = each.value.service.name
      location     = try(each.value.service.location, "europe-west1")
    }
  }
}

locals {
  all_services = merge(
    { for k, v in google_monitoring_custom_service.custom_service : k => v.service_id },
    { for k, v in google_monitoring_service.cloud_run_service : k => v.service_id }
  )
}

resource "google_monitoring_slo" "slo" {
  for_each = { for slo in flatten([
    for service in local.services_with_type : [
      for s in service.slos : merge(s, { service_name = service.service.name })
    ]
  ]) : "${slo.service_name}-${slo.formatted_name}" => slo }

  service      = local.all_services[each.value.service_name]
  slo_id       = each.value.formatted_name
  display_name = each.value.display_name
  project      = var.project
  goal         = each.value.goal
  user_labels  = merge(var.default_user_labels, each.value.user_labels)

  calendar_period     = try(each.value.calendar_period, null)
  rolling_period_days = try(each.value.rolling_period_days, null)

  dynamic "basic_sli" {
    for_each = try([each.value.basic_sli], [])
    content {
      method   = try(toset(basic_sli.value.method), null)
      location = try(toset(basic_sli.value.location), null)
      version  = try(toset(basic_sli.value.version), null)

      dynamic "latency" {
        for_each = try([basic_sli.value.latency], [])
        content {
          threshold = latency.value.threshold
        }
      }

      dynamic "availability" {
        for_each = try([basic_sli.value.availability], [])
        content {
          enabled = try(availability.value.enabled, true)
        }
      }
    }
  }


  dynamic "request_based_sli" {
    for_each = try([each.value.request_based_sli], [])
    content {
      dynamic "good_total_ratio" {
        for_each = try([request_based_sli.value.good_total_ratio], [])
        content {
          good_service_filter  = try(good_total_ratio.value.good_service_filter, null)
          bad_service_filter   = try(good_total_ratio.value.bad_service_filter, null)
          total_service_filter = try(good_total_ratio.value.total_service_filter, null)
        }
      }

      dynamic "distribution_cut" {
        for_each = try([request_based_sli.value.distribution_cut], [])
        content {
          distribution_filter = distribution_cut.value.distribution_filter
          range {
            min = try(distribution_cut.value.range.min, null)
            max = try(distribution_cut.value.range.max, null)
          }
        }
      }
    }
  }

  dynamic "windows_based_sli" {
    for_each = try([each.value.windows_based_sli], [])
    content {
      window_period          = try(windows_based_sli.value.window_period, null)
      good_bad_metric_filter = try(windows_based_sli.value.good_bad_metric_filter, null)

      dynamic "good_total_ratio_threshold" {
        for_each = try([windows_based_sli.value.good_total_ratio_threshold], [])
        content {
          threshold = good_total_ratio_threshold.value.threshold

          dynamic "performance" {
            for_each = try([good_total_ratio_threshold.value.performance], [])
            content {
              dynamic "good_total_ratio" {
                for_each = try([performance.value.good_total_ratio], [])
                content {
                  good_service_filter  = try(good_total_ratio.value.good_service_filter, null)
                  bad_service_filter   = try(good_total_ratio.value.bad_service_filter, null)
                  total_service_filter = try(good_total_ratio.value.total_service_filter, null)
                }
              }

              dynamic "distribution_cut" {
                for_each = try([performance.value.distribution_cut], [])
                content {
                  distribution_filter = distribution_cut.value.distribution_filter
                  range {
                    min = try(distribution_cut.value.range.min, null)
                    max = try(distribution_cut.value.range.max, null)
                  }
                }
              }
            }
          }

          dynamic "basic_sli_performance" {
            for_each = try([good_total_ratio_threshold.value.basic_sli_performance], [])
            content {
              method   = try(basic_sli_performance.value.method, null)
              location = try(basic_sli_performance.value.location, null)
              version  = try(basic_sli_performance.value.version, null)

              dynamic "latency" {
                for_each = try([basic_sli_performance.value.latency], [])
                content {
                  threshold = latency.value.threshold
                }
              }

              dynamic "availability" {
                for_each = try([basic_sli_performance.value.availability], [])
                content {
                  enabled = availability.value.enabled
                }
              }
            }
          }
        }
      }

      dynamic "metric_mean_in_range" {
        for_each = try([windows_based_sli.value.metric_mean_in_range], [])
        content {
          time_series = metric_mean_in_range.value.time_series
          range {
            min = try(metric_mean_in_range.value.range.min, null)
            max = try(metric_mean_in_range.value.range.max, null)
          }
        }
      }

      dynamic "metric_sum_in_range" {
        for_each = try([windows_based_sli.value.metric_sum_in_range], [])
        content {
          time_series = metric_sum_in_range.value.time_series
          range {
            min = try(metric_sum_in_range.value.range.min, null)
            max = try(metric_sum_in_range.value.range.max, null)
          }
        }
      }
    }
  }
}


resource "google_monitoring_alert_policy" "alert_policy" {
  for_each = { for slo in flatten([
    for service in local.services_with_type : [
      for s in service.slos : merge(s, { service_name = service.service.name })
    ]
  ]) : "${slo.service_name}-${slo.formatted_name}" => slo if lookup(slo, "alert", null) != null && lookup(slo.alert, "enabled", false) }

  project = var.project
  display_name = try(
    each.value.alert.title,
    "[${local.default_alert.prio}] ${each.value.service_name} | ${each.value.formatted_name} - High burnrate!"
  )
  combiner    = "OR"
  user_labels = merge(var.default_user_labels, each.value.user_labels)
  enabled     = try(each.value.alert.enabled, true)
  notification_channels = try(
    [for nc in each.value.alert.notification_channels : try(var.notification_channel_ids[nc], nc)],
    local.fallback_notification_channels
  )

  conditions {
    display_name = try(each.value.alert.condition_name, local.default_alert.condition_name)
    condition_threshold {
      filter          = "select_slo_burn_rate(\"${google_monitoring_slo.slo["${each.value.service_name}-${each.value.formatted_name}"].id}\", \"${try(each.value.alert.lookback_duration, local.default_alert.lookback_duration)}\")"
      duration        = try(each.value.alert.duration, local.default_alert.duration)
      comparison      = "COMPARISON_GT"
      threshold_value = try(each.value.alert.threshold_value, local.default_alert.threshold_value)
      trigger {
        count = 1
      }
    }
  }

  documentation {
    mime_type = "text/markdown"
    content = coalesce(
      try(each.value.alert.documentation, null),
      var.fallback_alert_documentation,
      try(local.default_alert.description, "")
    )
  }

  depends_on = [google_monitoring_slo.slo]
}
