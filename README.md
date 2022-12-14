## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12.18 |
| google | >= 4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| **display\_name** | Display name of the custom service | `string` | n/a | **yes** |
| **monitoring\_project\_id** | Project ID to create monitoring resources in | `string` | `"hiiretail-monitoring-prod-6500"` | no |
| **telemetry\_resource\_name** | The full name of the resource that defines this service | `string` | `""` | no |
| **slo\_config** | Configuration for SLO | `any` | n/a | **yes** |

## Outputs

| Name | Description |
|------|-------------|
| custom\_service | The custom service |
| slos | The SLOs |
