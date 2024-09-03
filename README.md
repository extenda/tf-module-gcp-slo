# GCP SLOs

For creating SLOs in GCP Monitoring.

## Usage

```hcl
module "gcp_slos" {
  source  = "path/to/module"
  project = "your-project-id"

  services = [
    {
      service = {
        name = "example-service"
        type = "CLOUD_RUN"
        user_labels = {
          team = "platform"
        }
      }
      slos = [
        {
          display_name = "Availability SLO"
          goal = 0.99
          rolling_period_days = 28
          basic_sli = {
            availability = {
              enabled = true
            }
          }
        }
      ]
    }
  ]
}
```

| Name                           | Description                                                                                                                                  | Type          | Default | Required |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ------- | :------: |
| project                        | Project ID to create monitoring resources in                                                                                                 | `string`      | n/a     |   yes    |
| default_user_labels            | User labels to be set for all alerts                                                                                                         | `map(any)`    | `{}`    |    no    |
| fallback_notification_channels | List of display names or ids for notification channels to be set for all alerts, if unspecified in the alert.                                | `list(any)`   | `[]`    |    no    |
| notification_channel_ids       | Enables you to provide the NCs 'display name' instead of 'id', { nc_display_name: nc_id } or output from tf-module-gcp-notification-channels | `map(string)` | `{}`    |    no    |
| fallback_alert_documentation   | Documentation to be set for all alerts, if unspecified in the alert.                                                                         | `string`      | `null`  |    no    |
| services                       | List of services and their SLOs                                                                                                              | `any`         | n/a     |   yes    |

## `services` object

This module is essentially a wrapper around the terraform resources. Refer to the documentation below to understand the structure of each object. Take a look in [examples](./examples/) for a better understanding of how to use this module.

📖 [Terraform Docs](https://registry.terraform.io/providers/hashicorp/google/6.0.1/docs/resources/monitoring_slo) \
✅ [Examples](./examples/)

```hcl
services = [
  {
    service = {
      name                    = string
      type                    = string       # "CUSTOM" or "CLOUD_RUN"
      user_labels             = map(string)  # Optional
      telemetry_resource_name = string       # Optional, for CUSTOM services
    }
    slos = [
      {
        display_name        = string
        goal                = number
        rolling_period_days = number       # Optional
        calendar_period     = string       # Optional, one of "DAY", "WEEK", "FORTNIGHT", "MONTH"
        user_labels         = map(string)  # Optional

        # One of the following SLI types must be specified:
        basic_sli = {
          # ... (structure as per Terraform documentation)
        }
        request_based_sli = {
          # ... (structure as per Terraform documentation)
        }
        windows_based_sli = {
          # ... (structure as per Terraform documentation)
        }

        alert = {
          enabled               = bool    # Optional
          title                 = string  # Optional
          documentation         = string  # Optional
          threshold_value       = number  # Optional
          condition_name        = string  # Optional
          lookback_duration     = string  # Optional
          threshold_value       = number  # Optional
          duration              = string  # Optional
          notification_channels = list(string)  # Optional
        }
      }
    ]
  }
]
```

## Outputs

### `services` output structure

```hcl
{
  "service_name" = {
    id   = string
    name = string
    type = string  # "CUSTOM" or "CLOUD_RUN"
  }
}
```

### `slos` output structure

```hcl
{
  "service_name-slo_name" = {
    id           = string
    name         = string
    service_name = string
  }
}
```

### `alerts` output structure

```hcl
{
  "service_name-slo_name" = {
    id           = string
    name         = string
    service_name = string
  }
}
```
