## Inputs

| Name                               | Description                                                                                                                                                                        | Type        | Default | Required |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- | ------- | :------: |
| __project__                        | Project ID to create alerts in                                                                                                                                                     | `string`    | n/a     |   yes    |
| __service_name__                   | Display name of the custom service                                                                                                                                                 | `string`    | n/a     |   yes    |
| __telemetry_resource_name__        | The full name of the resource that defines this service                                                                                                                            | `string`    | n/a     |    no    |
| __default_user_labels__            | Labels to be set for __all__ alerts                                                                                                                                                | `map(any)`  | {}      |    no    |
| __fallback_notification_channels__ | NCs to be set for all alerts that don't provide `notification_channels`. Provide the NCs "id" or "display name" (the latter is dependant on the notification_channel_ids variable) | `list(any)` | []      |    no    |
| __notification_channel_ids__       | To be able to provide channels display name instead of id/name, provide a  be { display_name: name } or output from tf-module-gcp-notification-channels.                           | `list(any)` | []      |    no    |
| __default_alert_documentation__    | Documentation to be set for all burn-rate alerts.                                                                                                                                  | `string`    | n/a     |    no    |
| __slos__                           | The list of alert policies configurations.                                                                                                                                         | `list(any)` | n/a     |   yes    |

## Burn rate alerting

All SLOs will have a burn rate alert included, this alert has the following conditions and will go off if any are met.

- 2% of error budget consumed in 1 hour
- 5% of error budget consumed in 6 hours
- 10% of error budget consumed in in 3 days

If you don’t want an alert you can just leave the alert empty, like the example below.

```yaml
- display_name: Example SLO
  ...
  alert: false
```

## Outputs

| Name           | Description         |
| -------------- | ------------------- |
| custom service | The custom service  |
| slos           | The SLOs            |
| alert          | The burn-rate alert |
