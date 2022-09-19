resource "google_monitoring_custom_service" "custom_service" {
  project      = var.monitoring_project_id
  display_name = var.service_name
  telemetry {
    resource_name = var.telemetry_resource_name
  }
}

resource "google_monitoring_slo" "slo" {
  for_each = { for slo in var.slos : slo.slo_id => slo }

  service             = google_monitoring_custom_service.custom_service.service_id
  project             = var.monitoring_project_id
  slo_id              = each.value.slo_id
  display_name        = each.value.display_name
  goal                = each.value.goal
  calendar_period     = lookup(each.value, "calendar_period", null)
  rolling_period_days = lookup(each.value, "rolling_period_days", null)

  dynamic "basic_sli" {
    for_each = lookup(each.value, "type") == "basic_sli" ? ["yes"] : []
    content {
      latency {
        threshold = lookup(each.value, "latency_threshold", null)
      }
    }
  }

  dynamic "request_based_sli" {
    for_each = lookup(each.value, "type") == "request_based_sli" ? ["yes"] : []
    content {

      dynamic "distribution_cut" {
        for_each = lookup(each.value, "method", null) == "distribution_cut" ? ["yes"] : []
        content {
          distribution_filter = lookup(each.value, "metric_filter", null)
          range {
            min = lookup(each.value, "range_min", null)
            max = lookup(each.value, "range_max", null)
          }
        }
      }

      dynamic "good_total_ratio" {
        for_each = lookup(each.value, "method", null) == "good_total_ratio" ? ["yes"] : []
        content {
          good_service_filter  = lookup(each.value, "good_service_filter", null)
          bad_service_filter   = lookup(each.value, "bad_service_filter", null)
          total_service_filter = lookup(each.value, "total_service_filter", null)
        }
      }
    }
  }

  dynamic "windows_based_sli" {
    for_each = lookup(each.value, "type") == "windows_based_sli" ? ["yes"] : []
    content {
      window_period = lookup(each.value, "window_period", null)

      good_bad_metric_filter = lookup(each.value, "method", null) == "boolean_filter" ? lookup(each.value, "metric_filter", null) : null

      dynamic "good_total_ratio_threshold" {
        for_each = lookup(each.value, "method", null) == "performance_window" ? ["yes"] : []
        content {
          threshold = lookup(each.value, "threshold", null)

          dynamic "performance" {
            for_each = lookup(each.value, "method_performance", null) == "good_total_ratio" || lookup(each.value, "method_performance", null) == "distribution_cut" ? ["yes"] : []
            content {
              dynamic "good_total_ratio" {
                for_each = lookup(each.value, "method_performance", null) == "good_total_ratio" ? ["yes"] : []
                content {
                  good_service_filter  = lookup(each.value, "good_service_filter", null)
                  bad_service_filter   = lookup(each.value, "bad_service_filter", null)
                  total_service_filter = lookup(each.value, "total_service_filter", null)
                }
              }
              dynamic "distribution_cut" {
                for_each = lookup(each.value, "method_performance", null) == "distribution_cut" ? ["yes"] : []
                content {
                  distribution_filter = lookup(each.value, "metric_filter", null)
                  range {
                    min = lookup(each.value, "range_min", null)
                    max = lookup(each.value, "range_max", null)
                  }
                }
              }
            }
          }

          dynamic "basic_sli_performance" {
            for_each = lookup(each.value, "method_performance", null) == "basic_sli_performance" ? ["yes"] : []
            content {
              method   = lookup(each.value, "api_method", null)
              location = lookup(each.value, "api_location", null)
              version  = lookup(each.value, "api_version", null)
              latency {
                threshold = lookup(each.value, "latency_threshold", null)
              }
            }
          }
        }
      }

      dynamic "metric_mean_in_range" {
        for_each = lookup(each.value, "method", null) == "metric_mean_in_range" ? ["yes"] : []
        content {
          time_series = lookup(each.value, "metric_filter", null)
          range {
            min = lookup(each.value, "range_min", null)
            max = lookup(each.value, "range_max", null)
          }
        }
      }

      dynamic "metric_sum_in_range" {
        for_each = lookup(each.value, "method", null) == "metric_sum_in_range" ? ["yes"] : []
        content {
          time_series = lookup(each.value, "metric_filter", null)
          range {
            min = lookup(each.value, "range_min", null)
            max = lookup(each.value, "range_max", null)
          }
        }
      }
    }
  }
}

resource "google_monitoring_alert_policy" "alert_policy" {
  for_each              = { for slo in var.slos : slo.slo_id => slo }
  project               = var.monitoring_project_id
  notification_channels = var.notification_channels
  display_name          = lookup(lookup(each.value, "alert", {}), "name", "[P2] ${var.service_name} SLO | ${each.value.slo_id} - High burnrate ")
  combiner              = lookup(lookup(each.value, "alert", {}), "combiner", "OR")

  dynamic "conditions" {
    for_each = { for alert in lookup(each.value, "conditions", [
      { name : "2% of error budget consumed in 1 hour", threshold_value : 14, time : "3600s" },
      { name : "5% of error budget consumed in 6 hours", threshold_value : 6, time : "21600s" },
      { name : "10% of error budget consumed in 3 days", threshold_value : 1, time : "259200s" },
    ]) : alert.name => alert }
    content {
      display_name = conditions.value.name
      condition_threshold {
        comparison      = lookup(conditions.value, "comparison", "COMPARISON_GT")
        duration        = lookup(conditions.value, "duration", "0s")
        threshold_value = lookup(conditions.value, "threshold_value")
        filter          = "select_slo_burn_rate(${lookup(lookup(google_monitoring_slo.slo, each.value.slo_id), "name")}, ${conditions.value.time})"
      }
    }
  }
  depends_on = [google_monitoring_slo.slo]
}
