locals {
  fallback_notification_channels = [for nc in var.fallback_notification_channels : try(var.notification_channel_ids[nc], nc)]
  default_alert_conditions = [
    { name : "2% of error budget consumed in 1 hour", threshold_value : 14, time : "3600s" },
    { name : "5% of error budget consumed in 6 hours", threshold_value : 6, time : "21600s" },
    /* { name : "10% of error budget consumed in 3 days", threshold_value : 1, time : "259200s" }, */
  ]
}

resource "google_monitoring_custom_service" "custom_service" {
  project      = var.project
  display_name = var.service_name
  user_labels  = var.default_user_labels

  telemetry {
    resource_name = var.telemetry_resource_name
  }
}

resource "google_monitoring_slo" "slo" {
  for_each = { for slo in var.slos : slo.slo_id => slo }

  service             = google_monitoring_custom_service.custom_service.service_id
  project             = var.project
  slo_id              = each.value.slo_id
  display_name        = each.value.display_name
  goal                = each.value.goal
  user_labels         = merge(var.default_user_labels, try(each.value.user_labels, {}))
  calendar_period     = try(each.value.calendar_period, null)
  rolling_period_days = try(each.value.rolling_period_days, null)


  dynamic "basic_sli" {
    for_each = each.value.type == "basic_sli" ? [1] : []
    content {
      latency {
        threshold = try(each.value.latency_threshold, null)
      }
    }
  }

  dynamic "request_based_sli" {
    for_each = each.value.type == "request_based_sli" ? [1] : []
    content {
      dynamic "distribution_cut" {
        for_each = each.value.method == "distribution_cut" ? [1] : []
        content {
          distribution_filter = try(each.value.metric_filter, null)
          range {
            min = try(each.value.range_min, null)
            max = try(each.value.range_max, null)
          }
        }
      }

      dynamic "good_total_ratio" {
        for_each = each.value.method == "good_total_ratio" ? [1] : []
        content {
          good_service_filter  = try(each.value.good_service_filter, null)
          bad_service_filter   = try(each.value.bad_service_filter, null)
          total_service_filter = try(each.value.total_service_filter, null)
        }
      }
    }
  }

  dynamic "windows_based_sli" {
    for_each = each.value.type == "windows_based_sli" ? [1] : []
    content {
      window_period          = try(each.value.window_period, null)
      good_bad_metric_filter = each.value.method == "boolean_filter" ? try(each.value.metric_filter, null) : null

      dynamic "good_total_ratio_threshold" {
        for_each = try(each.value.method, null) == "performance_window" ? [1] : []
        content {
          threshold = try(each.value.threshold, null)
          dynamic "performance" {
            for_each = try(each.value.method_performance, null) == "good_total_ratio" || try(each.value.method_performance, null) == "distribution_cut" ? [1] : []
            content {
              dynamic "good_total_ratio" {
                for_each = try(each.value.method_performance, null) == "good_total_ratio" ? [1] : []
                content {
                  good_service_filter  = try(each.value.good_service_filter, null)
                  bad_service_filter   = try(each.value.bad_service_filter, null)
                  total_service_filter = try(each.value.total_service_filter, null)
                }
              }

              dynamic "distribution_cut" {
                for_each = try(each.value.method_performance, null) == "distribution_cut" ? [1] : []
                content {
                  distribution_filter = try(each.value.metric_filter, null)
                  range {
                    min = try(each.value.range_min, null)
                    max = try(each.value.range_max, null)
                  }
                }
              }
            }
          }

          dynamic "basic_sli_performance" {
            for_each = try(each.value.method_performance, null) == "basic_sli_performance" ? [1] : []
            content {
              method   = try(each.value.api_method, null)
              location = try(each.value.api_location, null)
              version  = try(each.value.api_version, null)
              latency {
                threshold = try(each.value.latency_threshold, null)
              }
            }
          }
        }
      }

      dynamic "metric_mean_in_range" {
        for_each = try(each.value.method, null) == "metric_mean_in_range" ? [1] : []
        content {
          time_series = try(each.value.metric_filter, null)
          range {
            min = try(each.value.range_min, null)
            max = try(each.value.range_max, null)
          }
        }
      }

      dynamic "metric_sum_in_range" {
        for_each = try(each.value.method, null) == "metric_sum_in_range" ? [1] : []
        content {
          time_series = try(each.value.metric_filter, null)
          range {
            min = try(each.value.range_min, null)
            max = try(each.value.range_max, null)
          }
        }
      }
    }
  }
}

resource "google_monitoring_alert_policy" "alert_policy" {
  for_each = { for slo in var.slos : slo.slo_id => slo if try(slo.alert, true) }

  project      = var.project
  display_name = "[P2] ${var.service_name} SLO | ${each.value.slo_id} - High burnrate "
  combiner     = "OR"
  user_labels  = null
  notification_channels = try(
    [for nc in each.value.notification_channels : try(var.notification_channel_ids[nc], nc)],
    local.fallback_notification_channels,
  )

  dynamic "conditions" {
    for_each = local.default_alert_conditions
    content {
      display_name = conditions.value.name
      condition_threshold {
        comparison      = "COMPARISON_GT"
        duration        = "60s"
        threshold_value = conditions.value.threshold_value
        filter          = "select_slo_burn_rate(${google_monitoring_slo.slo[each.value.slo_id].name}, ${conditions.value.time})"
      }
    }
  }

  documentation {
    mime_type = "text/markdown"
    content   = try(each.value.documentation, var.default_alert_documentation)
  }

  depends_on = [google_monitoring_slo.slo]
}
